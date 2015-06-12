require 'chef/provisioning/driver'
require 'chef/provisioning/machine/windows_machine'
require 'chef/provisioning/machine/unix_machine'
require 'chef/provisioning/transport/winrm'
require 'chef/provisioning/transport/ssh'
require 'chef/provisioning/convergence_strategy/install_cached'
require 'chef/provisioning/hyperv_driver/version'
require 'hyperv/hyperv_api'
require 'uri'

class Chef
  module Provisioning
    module HyperVDriver
      class Driver < Chef::Provisioning::Driver
        # The format for driver url is hyperv:<hyperv host url>
        # Ex- hyperv:https://10.10.121.20:8080
        def self.canonicalize_url(driver_url, _config)
          hyperv, hyperv_host_url = driver_url.split(':', 2)

          # Validate URL
          begin
            hyperv_host_url = URI.parse(hyperv_host_url)
            hyperv_host_url.to_s
          rescue URI::InvalidURIError => e
            Chef::Log.fatal(e.to_s)
            raise URI::InvalidURIError
          end
        end

        def self.from_url(driver_url, config)
          Driver.new(driver_url, config)
        end

        def initialize(driver_url, config)
          super(driver_url, config)

          # Use the config object to get hyperv credentials and initialize
          # Hyperv::Server object during initialize.
          hyerv_creds = hyperv_auth_credentials(config)
          @hyperv_host = HyperV::Host.new(
            driver_url, hyerv_creds[:username], hyerv_creds[:password])
        end

        def allocate_machine(action_handler, machine_spec, machine_options)
          # Handle all the validations over here
          # To-do
          # Handle the case where the machine's hardware resources have changed.
          #
          # machine_spec lists the current configuration of the vm.
          # machine_options lists the desired configuration of the vm.
          # Compare machine_spec and machine_options

          # Assuming the unique identifier for each VM is its name.
          if machine_spec.name
            # Check if the hyperv server exists.
            unless @hyperv_host.valid_server?(machine_spec.name)
              # Server doesn't exist
              msg = "Machine #{machine_spec.name} does not really exist.  Recreating ..."
              action_handler.perform_action msg do
                machine_spec.name = nil
              end
            end
          end

          # Create a new server if server doesn't exist.
          unless machine_spec.name
            msg = "Creating server #{machine_options.name} with "
            msg += "options #{machine_options.vm_options}"

            action_handler.perform_action msg  do
              # create_server shouldn't be a blocking method.
              create_server(machine_options.vm_options)

              machine_spec.vm_options = machine_options.vm_options
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

        def machine_for(machine_spec, _machine_options)
          server_id = machine_spec.reference['server_id']
          hostname = @server.get_hostname(server_id)
          transport = @server.get_transport_type(server_id)
          ssh_options = {
            auth_methods: ['publickey'],
            keys: [get_key('bootstrapkey')]
          }

          if transport == 'ssh'
            create_ssh_transport
          else
            create_winrm_transport
          end
        end

        def destroy_machine(action_handler, machine_spec, _machine_options)
          if machine_spec.reference
            server_id = machine_spec.reference['server_id']
            action_handler.perform_action "Destroy machine #{server_id}" do
              @server.destroy_machine(server_id)
              machine_spec.reference = nil
            end
          end
        end

        def stop_machine(action_handler, machine_spec, _machine_options)
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

        def hyperv_auth_credentials(config)
          unless config.configs[0][:driver_options][:compute_options][:username] &&
                 config.configs[0][:driver_options][:compute_options][:password]

            fail ArgumentError.new('Usename or password missing.')
          end

          config.configs[0][:driver_options][:compute_options]
        end
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
            user: machine_spec.location['winrm.username'] || 'vagrant',
            pass: machine_spec.location['winrm.password'] || 'vagrant',
            disable_sspi: true
          }

          Chef::Provisioning::Transport::WinRM.new(endpoint, type, options)
        end

        def create_ssh_transport(machine_spec)
          vagrant_ssh_config = vagrant_ssh_config_for(machine_spec)
          hostname = vagrant_ssh_config['HostName']
          username = vagrant_ssh_config['User']
          ssh_options = {
            port: vagrant_ssh_config['Port'],
            auth_methods: ['publickey'],
            user_known_hosts_file: vagrant_ssh_config['UserKnownHostsFile'],
            paranoid: yes_or_no(vagrant_ssh_config['StrictHostKeyChecking']),
            keys: [strip_quotes(vagrant_ssh_config['IdentityFile'])],
            keys_only: yes_or_no(vagrant_ssh_config['IdentitiesOnly'])
          }
          ssh_options[:auth_methods] = %w(password) if yes_or_no(vagrant_ssh_config['PasswordAuthentication'])
          options = {
            prefix: 'sudo '
          }
          Chef::Provisioning::Transport::SSH.new(hostname, username, ssh_options, options, config)
        end
      end
    end
  end
end
