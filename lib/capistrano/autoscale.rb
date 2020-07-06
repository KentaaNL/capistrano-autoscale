# frozen_string_literal: true

require 'capistrano/all'
require 'aws-sdk-autoscaling'
require 'aws-sdk-ec2'

require 'capistrano/autoscale/version'
require 'capistrano/autoscale/logger'
require 'capistrano/autoscale/dsl'

require 'capistrano/autoscale/errors/create_image_failed'
require 'capistrano/autoscale/errors/no_launch_template'

require 'capistrano/autoscale/aws/base'
require 'capistrano/autoscale/aws/taggable'
require 'capistrano/autoscale/aws/instance_collection'
require 'capistrano/autoscale/aws/instance'
require 'capistrano/autoscale/aws/autoscale_group'
require 'capistrano/autoscale/aws/launch_template'
require 'capistrano/autoscale/aws/ami'
require 'capistrano/autoscale/aws/snapshot'

load File.expand_path('tasks/autoscale.rake', __dir__)
