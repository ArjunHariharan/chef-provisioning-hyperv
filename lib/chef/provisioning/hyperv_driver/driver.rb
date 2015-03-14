require 'chef/provisioning/driver'

class Chef
  module Provisioning
    module HyperVDriver
      class Driver < Chef::Provisioning::Driver
        def self.from_url(url, config)
          Driver.new(driver_url, config)
        end

        def initialize(url, config)
          super(driver_url, config)
        end

        # Write the logic to parse hyperv url
        def cloud_url
          scheme, cloud_url = url.split(':', 2)
          cloud_url
        end

        def hyperv_connection
          Hyperv.connect(cloud_url, driver_config['username'],
            driver_config['password'])
        end
      end
    end
  end
end