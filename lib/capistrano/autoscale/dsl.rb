# frozen_string_literal: true

module Capistrano
  module Autoscale
    module DSL
      include Capistrano::Autoscale::Logger

      def autoscale(groupname, properties = {})
        group_names = fetch(:aws_autoscale_group_names)
        group_names << groupname

        asg = Capistrano::Autoscale::AWS::AutoscaleGroup.new groupname
        instances = asg.instances.running

        info "Auto Scaling Group: #{groupname}"

        instances.each.with_index do |instance, index|
          info "Adding server #{instance.private_ip}"

          if index.zero? && properties.key?(:primary_roles)
            server_properties = properties.dup
            server_properties[:roles] = server_properties.delete(:primary_roles)
          else
            server_properties = properties
          end

          server(instance.private_ip, server_properties)
        end

        if instances.any?
          after 'deploy', 'autoscale:update'

          if fetch(:aws_autoscale_suspend_processes)
            before 'deploy', 'autoscale:suspend'

            after 'deploy', 'autoscale:resume'
            after 'deploy:failed', 'autoscale:resume'
          end
        else
          error <<~MESSAGE
            Will not create AMI because no running instances were found in the specified Auto Scaling group. Ensure that the Auto Scaling group name is correct and that there is at least one running instance attached to it.
          MESSAGE
        end
      end
    end
  end
end

extend Capistrano::Autoscale::DSL # rubocop:disable Style/MixinUsage
