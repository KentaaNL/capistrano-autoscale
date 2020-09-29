# frozen_string_literal: true

module Capistrano
  module Autoscale
    module AWS
      class AutoscaleGroup < Base
        SUSPEND_PROCESSES = %w[Launch Terminate].freeze

        LIFECYCLE_STATE_IN_SERVICE = 'InService'
        LIFECYCLE_STATE_STANDBY = 'Standby'

        AMI_PREFIX_TAG = 'Autoscale-Ami-Prefix'

        attr_reader :name, :aws_counterpart

        def initialize(name)
          @name = name
          @aws_counterpart = Aws::AutoScaling::AutoScalingGroup.new name: name, client: autoscaling_client

          raise Capistrano::Autoscale::Errors::NoAutoScalingGroup, name unless @aws_counterpart.exists?
        end

        def instances
          instance_ids = aws_counterpart.instances.map(&:instance_id)
          InstanceCollection.new(instance_ids)
        end

        def instances_in_service
          instance_ids = aws_counterpart.instances.select { |i| i.lifecycle_state == LIFECYCLE_STATE_IN_SERVICE }.map(&:instance_id)
          InstanceCollection.new(instance_ids)
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
          aws_counterpart.suspend_processes(scaling_processes: SUSPEND_PROCESSES)
        end

        def resume
          aws_counterpart.resume_processes(scaling_processes: SUSPEND_PROCESSES)
        end

        def suspended?
          aws_counterpart.suspended_processes.map(&:process_name).any? { |name| SUSPEND_PROCESSES.include?(name) }
        end

        def tags
          aws_counterpart.tags.map { |tag| [tag.key, tag.value] }.to_h
        end

        def ami_prefix
          tags[AMI_PREFIX_TAG]
        end

        def enter_standby(instance)
          instance = aws_counterpart.instances.select { |i| i.id == instance.id }.first
          instance.enter_standby(should_decrement_desired_capacity: true)

          loop do
            break if instance.lifecycle_state == LIFECYCLE_STATE_STANDBY

            sleep 1
            instance.load
          end
        end

        def exit_standby(instance)
          instance = aws_counterpart.instances.select { |i| i.id == instance.id }.first
          instance.exit_standby
        end

        private

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
