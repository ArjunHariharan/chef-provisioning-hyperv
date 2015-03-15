require 'chef/provisioning/driver'
require 'chef/provisioning/machine/windows_machine'
require 'chef/provisioning/machine/unix_machine'
require 'chef/provisioning/transport/winrm'
require 'chef/provisioning/transport/ssh_transport'
require 'chef/provisioning/convergence_strategy/install_cached'
require 'chef/provisioning/hyperv_driver/version'
require 'hyperv/hyperv_api'

class Chef
  module Provisioning
    module HyperVDriver
      class Driver < Chef::Provisioning::Driver

        def self.from_url(url, config)
          Driver.new(driver_url, config)
        end

        def initialize(url, config)
          super(driver_url, config)
          @server = HyperV::Server.new
        end

        def allocate_machine(action_handler, machine_spec, machine_options)
          # Handle all the validations over here
          # To-do
          # Handle the case where the machine's hardware resources have changed.
          # Compare machine_spec and machine_options
          if machine_spec.reference
            # Check if the hyperv server exists.
            unless @server.valid_server?(driver_url, machine_spec.reference['server_id'])
              # Server doesn't exist
              msg = 'Machine #{machine_spec.reference['server_id']} does not really exist.  Recreating ...'
              action_handler.perform_action msg do
                machine_spec.reference = nil
              end
            end
          end

          # Create a new server if server doesn't exist.
          unless machine_spec.reference
            msg = 'Creating server #{machine_spec.name} with options #{machine_options}'
            action_handler.perform_action msg  do
              # create_server shouldn't be a blocking method.
              server_id = create_server(machine_spec.name, machine_spec.os,
                                        machine_spec.user, machine_spec.password)
              machine_spec.reference = {
                'driver_url' => driver_url,
                'driver_version' => MyDriver::VERSION,
                'server_id' => server_id,
              }
            end
          end
        end

        def ready_machine(action_handler, machine_spec, machine_options)
          server_id = machine_spec.reference['server_id']
          if @server.machine_status(server_id) == 'stopped'
            action_handler.perform_action "Powering up machine #{server_id}" do
              @server.power_on(server_id)
            end
          end

          if @server.machine_status(server_id) != 'ready'
            # action_handler.perform_action "wait for machine #{server_id}" do
            #   @server.wait_for_ready(server_id, 'ready')
            # end
          end

          # Return the Machine object
          machine_for(machine_spec, machine_options)
        end

        def machine_for(machine_spec, machine_options)
          server_id = machine_spec.reference['server_id']
          hostname = @server.get_hostname(server_id)
          transport = @server.get_transport_type(server_id)
          ssh_options = {
            :auth_methods => ['publickey'],
            :keys => [ get_key('bootstrapkey') ],
          }

          if transport == 'ssh'
            create_ssh_transport
          else
            create_winrm_transport
          end
        end

        def destroy_machine(action_handler, machine_spec, machine_options)
          if machine_spec.reference
            server_id = machine_spec.reference['server_id']
            action_handler.perform_action "Destroy machine #{server_id}" do
              @server.destroy_machine(server_id)
              machine_spec.reference = nil
            end
          end
        end

        def stop_machine(action_handler, machine_spec, machine_options)
          if machine_spec.reference
            server_id = machine_spec.reference['server_id']
            action_handler.perform_action "Power off machine #{server_id}" do
              @server.power_off(server_id)
            end
          end
        end

        def connect_to_machine(machine_spec, machine_options)
          machine_for(machine_spec, machine_options)
        end

        protected

        # verify hyperv lwrp using Chef::Provision.inline_resource
        # Call from allocate_machine
        # def validate_resource(action_handler)
          # Chef::Provisioning.inline_resource(action_handler) do
          #   hyperv_resource
          # end
        # end

        def hyperv_connection
          @server.connect(cloud_url, driver_config['username'],
            driver_config['password'])
        end

        # Write the logic to parse hyperv url
        # def url
          # scheme, cloud_url = url.split(':', 2)
          # cloud_url
        # end

        def create_winrm_transport(machine_spec)
          forwarded_ports = machine_spec.location['forwarded_ports']

          # TODO IPv6 loopback?  What do we do for that?
          hostname = machine_spec.location['winrm.host'] || '127.0.0.1'
          port = machine_spec.location['winrm.port'] || 5985
          port = forwarded_ports[port] if forwarded_ports[port]
          endpoint = "http://#{hostname}:#{port}/wsman"
          type = :plaintext
          options = {
            :user => machine_spec.location['winrm.username'] || 'vagrant',
            :pass => machine_spec.location['winrm.password'] || 'vagrant',
            :disable_sspi => true
          }

          Chef::Provisioning::Transport::WinRM.new(endpoint, type, options)
        end

        def create_ssh_transport(machine_spec)
          vagrant_ssh_config = vagrant_ssh_config_for(machine_spec)
          hostname = vagrant_ssh_config['HostName']
          username = vagrant_ssh_config['User']
          ssh_options = {
            :port => vagrant_ssh_config['Port'],
            :auth_methods => ['publickey'],
            :user_known_hosts_file => vagrant_ssh_config['UserKnownHostsFile'],
            :paranoid => yes_or_no(vagrant_ssh_config['StrictHostKeyChecking']),
            :keys => [ strip_quotes(vagrant_ssh_config['IdentityFile']) ],
            :keys_only => yes_or_no(vagrant_ssh_config['IdentitiesOnly'])
          }
          ssh_options[:auth_methods] = %w(password) if yes_or_no(vagrant_ssh_config['PasswordAuthentication'])
          options = {
            :prefix => 'sudo '
          }
          Chef::Provisioning::Transport::SSH.new(hostname, username, ssh_options, options, config)
        end
      end
    end
  end
end