# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chef/provisioning/hyperv_driver/version'

Gem::Specification.new do |spec|
  spec.name          = "chef-provisioning-hyperv"
  spec.version       = Chef::Provisioning::HyperVDriver::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ["Arjun"]
  spec.email         = ["arjun.hariharan@clogeny.com"]
  spec.summary       = 'Chef provisioner for hyper-v'
  spec.description   = 'Chef provisioner for hyper-v'
  spec.homepage      = 'https://github.com/ArjunHariharan/chef-provisioning-hyperv'
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'chef'
  spec.add_dependency 'chef-provisioning', '~> 0.19'

  spec.add_development_dependency "rake", "~> 10.0"
end
