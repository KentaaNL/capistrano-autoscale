# frozen_string_literal: true

module Capistrano
  module Autoscale
    module AWS
      class InstanceCollection < Base
        include Enumerable

        attr_reader :instances

        def initialize(ids)
          @instances = query_instances_by_ids(ids).map do |i|
            Instance.new(i.instance_id, i.private_ip_address, i.state.code)
          end
        end

        def running
          select(&:running?)
        end

        def each(&block)
          instances.each(&block)
        end

        private

        def query_instances_by_ids(ids)
          return [] if ids.empty?

          ec2_client
            .describe_instances(instance_ids: ids)
            .reservations.flat_map(&:instances)
        end
      end
    end
  end
end
