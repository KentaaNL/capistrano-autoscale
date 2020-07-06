# frozen_string_literal: true

module Capistrano
  module Autoscale
    module AWS
      class Snapshot < Base
        include Taggable

        attr_reader :id, :aws_counterpart

        def initialize(id)
          @id = id
          @aws_counterpart = ::Aws::EC2::Snapshot.new id, client: ec2_client
        end

        def delete
          ec2_client.delete_snapshot snapshot_id: id
        end
      end
    end
  end
end
