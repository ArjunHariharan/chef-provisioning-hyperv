require 'chef/provisioning/driver'
require 'hyperv/hyperv_api'

class Chef
  module Provisioning
    module HyperVDriver
      class Driver < Chef::Provisioning::Driver

        include HyperV::API

        def self.from_url(url, config)
          Driver.new(driver_url, config)
        end

        def initialize(url, config)
          super(driver_url, config)
        end


        def allocate_machine(action_handler, machine_spec, machine_options)
          if machine_spec.reference
            # Check if the hyperv server exists.
            unless valid_server?(driver_url, machine_spec.reference['server_id'])
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

        protected

        # verify hyperv lwrp using Chef::Provision.inline_resource
        # Call from allocate_machine
        # def validate_resource(action_handler)
          # Chef::Provisioning.inline_resource(action_handler) do
          #   hyperv_resource
          # end
        # end

        def hyperv_connection
          Hyperv.connect(cloud_url, driver_config['username'],
            driver_config['password'])
        end

        # Write the logic to parse hyperv url
        # def url
          # scheme, cloud_url = url.split(':', 2)
          # cloud_url
        # end
      end
    end
  end
end