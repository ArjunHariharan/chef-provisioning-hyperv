require 'chef/provisioning/hyperv_driver/driver'

Chef::Provisioning.register_driver_class('hyperv', Chef::Provisioning::HyperVDriver::Driver)