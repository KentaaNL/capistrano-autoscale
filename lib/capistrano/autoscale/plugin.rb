# frozen_string_literal: true

module Capistrano
  module Autoscale
    class Plugin < Capistrano::Plugin
      include Capistrano::Autoscale::Logger

      def set_defaults
        set_if_empty :aws_autoscale_ami_prefix, fetch(:stage)
        set_if_empty :aws_autoscale_ami_tags, {}
        set_if_empty :aws_autoscale_snapshot_tags, {}
        set_if_empty :aws_autoscale_suspend_processes, true
      end

      def define_tasks
        eval_rakefile File.expand_path('../tasks/autoscale.rake', __dir__)
      end
    end
  end
end
