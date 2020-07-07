# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano/autoscale/version'

Gem::Specification.new do |spec|
  spec.name          = 'capistrano-autoscale'
  spec.version       = Capistrano::Autoscale::VERSION
  spec.authors       = ['Logan Serman']
  spec.email         = ['loganserman@gmail.com']
  spec.summary       = 'Capistrano plugin for deploying to AWS Auto Scaling Groups.'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/KentaaNL/capistrano-autoscale'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.3.0'

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0', '> 3.0'
  spec.add_development_dependency 'webmock', '~> 3.8'
  spec.add_development_dependency 'webmock-rspec-helper', '~> 0.0.5'

  spec.add_dependency 'aws-sdk-autoscaling', '~> 1'
  spec.add_dependency 'aws-sdk-ec2', '~> 1'
  spec.add_dependency 'capistrano', '~> 3.9', '> 3.9'
end
