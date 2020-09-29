# frozen_string_literal: true

module Capistrano
  module Autoscale
    module AWS
      class AMI < Base
        include Taggable

        DEPLOY_GROUP_TAG = 'Autoscale-Deploy-group'

        attr_reader :aws_counterpart, :id, :snapshots

        def initialize(id, block_device_mappings = [])
          @id = id
          @aws_counterpart = ::Aws::EC2::Image.new id, client: ec2_client

          @snapshots = block_device_mappings.map do |mapping|
            Capistrano::Autoscale::AWS::Snapshot.new mapping&.ebs&.snapshot_id
          end
        end

        def deploy_group
          tags[DEPLOY_GROUP_TAG]
        end

        def delete
          ec2_client.deregister_image image_id: id
          snapshots.each(&:delete)
        end

        def self.create(instance, prefix: 'autoscale', no_reboot: false)
          name = "#{prefix}-#{Time.now.to_i}"

          image = instance.aws_counterpart.create_image(
            name: name,
            instance_id: instance.id,
            no_reboot: no_reboot
          )
          image = image.wait_until_exists

          block_device_mappings = nil
          # Wait until block_device_mappings/snapshots are available.
          loop do
            block_device_mappings = image.block_device_mappings
            snapshot_ids = block_device_mappings.map { |mapping| mapping.ebs&.snapshot_id }.compact
            break if !snapshot_ids.empty? || image.state == 'failed'

            sleep 1
            image.load
          end

          raise Capistrano::Autoscale::Errors::CreateImageFailed, image if image.state == 'failed'

          ami = new image.id, block_device_mappings
          ami.tag 'Name', name
          ami.snapshots.each { |snapshot| snapshot.tag 'Name', name }
          ami
        end

        def create_tags(deploy_group)
          tag(DEPLOY_GROUP_TAG, deploy_group)

          aws_autoscale_ami_tags.each { |key, value| tag(key, value) }

          snapshots.each(&:create_tags)
        end
      end
    end
  end
end
