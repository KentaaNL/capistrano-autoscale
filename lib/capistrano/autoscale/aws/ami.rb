# frozen_string_literal: true

module Capistrano
  module Autoscale
    module AWS
      class AMI < Base
        include Taggable

        DEPLOY_ID_TAG = 'Autoscale-Deploy-id'
        DEPLOY_GROUP_TAG = 'Autoscale-Deploy-group'

        attr_reader :id, :snapshots

        def initialize(id, snapshots = [])
          @id = id
          @aws_counterpart = ::Aws::EC2::Image.new id, client: ec2_client

          @snapshots = snapshots.map do |snapshot|
            Capistrano::Autoscale::AWS::Snapshot.new snapshot&.ebs&.snapshot_id
          end
        end

        def deploy_id
          tags[DEPLOY_ID_TAG]
        end

        def deploy_id=(value)
          tag(DEPLOY_ID_TAG, value)
        end

        def deploy_group
          tags[DEPLOY_GROUP_TAG]
        end

        def deploy_group=(value)
          tag(DEPLOY_GROUP_TAG, value)
        end

        def ancestors
          aws_amis_in_deploy_group
            .reject { |aws_ami| deploy_id_from_aws_tags(aws_ami.tags) == deploy_id }
            .map { |aws_ami| self.class.new aws_ami.image_id, aws_ami.block_device_mappings }
        end

        def delete
          ec2_client.deregister_image image_id: id
          snapshots.each(&:delete)
        end

        def self.create(instance, prefix: 'autoscale', no_reboot: true)
          name = "#{prefix}-#{Time.now.to_i}"

          image = instance.aws_counterpart.create_image(
            name: name,
            instance_id: instance.id,
            no_reboot: no_reboot
          )
          image = image.wait_until_exists

          block_device_mappings = nil
          # Wait until block_device_mappings are available.
          loop do
            block_device_mappings = image.block_device_mappings
            break unless block_device_mappings.empty?

            sleep 1
            image.load
          end

          raise Capistrano::Autoscale::Errors::CreateImageFailed, image if image.state == 'failed'

          ami = new image.id, block_device_mappings
          ami.tag 'Name', name
          ami.snapshots.each { |snapshot| snapshot.tag 'Name', name }
          ami
        end

        private

        def aws_amis_in_deploy_group
          ec2_client.describe_images(
            owners: ['self'],
            filters: [{
              name: "tag:#{DEPLOY_GROUP_TAG}",
              values: [deploy_group]
            }]
          ).images
        end

        def deploy_id_from_aws_tags(tags)
          tags.detect { |tag| tag.key == DEPLOY_ID_TAG }&.value
        end
      end
    end
  end
end
