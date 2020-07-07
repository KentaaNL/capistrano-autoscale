# frozen_string_literal: true

module Capistrano
  module Autoscale
    module AWS
      class AutoscaleGroup < Base
        SUSPEND_PROCESSES = %w[Launch Terminate].freeze

        attr_reader :name, :aws_counterpart

        def initialize(name)
          @name = name
          @aws_counterpart = query_autoscale_group_by_name(name)

          raise Capistrano::Autoscale::Errors::NoAutoScalingGroup, name unless @aws_counterpart
        end

        def instance_ids
          aws_counterpart.instances.map(&:instance_id)
        end

        def instances
          InstanceCollection.new instance_ids
        end

        def launch_template
          lts = aws_launch_template || aws_launch_template_specification
          raise Capistrano::Autoscale::Errors::NoLaunchTemplate unless lts

          LaunchTemplate.new(
            lts.launch_template_id,
            lts.launch_template_name,
            lts.version,
            false,
            nil
          )
        end

        def suspend
          autoscaling_client.suspend_processes(
            auto_scaling_group_name: name,
            scaling_processes: SUSPEND_PROCESSES
          )
        end

        def resume
          autoscaling_client.resume_processes(
            auto_scaling_group_name: name,
            scaling_processes: SUSPEND_PROCESSES
          )
        end

        private

        def autoscaling_client
          @autoscaling_client ||= ::Aws::AutoScaling::Client.new(aws_options)
        end

        def query_autoscale_group_by_name(name)
          autoscaling_client
            .describe_auto_scaling_groups(auto_scaling_group_names: [name])
            .auto_scaling_groups
            .first
        end

        def aws_launch_template
          aws_counterpart.launch_template
        end

        def aws_launch_template_specification
          aws_counterpart.mixed_instances_policy&.launch_template
            &.launch_template_specification
        end
      end
    end
  end
end
