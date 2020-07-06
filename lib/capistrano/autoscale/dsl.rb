# frozen_string_literal: true

module Capistrano
  module Autoscale
    module DSL
      include Capistrano::Autoscale::Logger

      def autoscale(groupname, properties = {})
        set :aws_autoscale_group_name, groupname

        asg = Capistrano::Autoscale::AWS::AutoscaleGroup.new groupname
        instances = asg.instances.running

        instances.each.with_index do |instance, i|
          info "Adding server #{instance.private_ip}"

          props = nil
          props = yield(instance, i) if block_given?
          props ||= properties

          server instance.private_ip, props
        end

        if instances.any?
          after 'deploy', 'autoscale:deploy'

          if fetch(:aws_autoscale_suspend_processes)
            before 'deploy', 'autoscale:suspend'

            after 'deploy', 'autoscale:resume'
            after 'deploy:failed', 'autoscale:resume'
          end
        else
          error <<~MESSAGE
            Could not create AMI because no running instances were found in the specified AutoScale group. Ensure that the AutoScale group name is correct and that there is at least one running instance attached to it.
          MESSAGE
        end
      end
    end
  end
end

extend Capistrano::Autoscale::DSL # rubocop:disable Style/MixinUsage
