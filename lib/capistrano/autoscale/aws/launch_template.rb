# frozen_string_literal: true

module Capistrano
  module Autoscale
    module AWS
      class LaunchTemplate < Base
        attr_reader :id, :name, :version, :default, :image_id

        def initialize(id, name, version, default, image_id)
          @id = id
          @name = name
          @version = version
          @default = default
          @image_id = image_id
        end

        def update(ami, description: nil)
          latest = ec2_client.create_launch_template_version(
            launch_template_data: { image_id: ami.id },
            launch_template_id: id,
            source_version: version.to_s,
            version_description: description
          ).launch_template_version

          self.class.new(
            latest&.launch_template_id,
            latest&.launch_template_name,
            latest&.version_number,
            latest&.default_version,
            latest&.launch_template_data&.image_id
          )
        end

        def previous_versions
          ec2_client.describe_launch_template_versions(launch_template_id: id)
                    .launch_template_versions.sort_by(&:version_number).reverse
                    .select { |v| v.version_number < version }
                    .map { |v| self.class.new(v.launch_template_id, v.launch_template_name, v.version_number, v.default_version, v.launch_template_data.image_id) }
        end

        def ami
          @ami ||= begin
            image = ::Aws::EC2::Image.new(image_id, client: ec2_client)
            AMI.new(image.image_id, image.block_device_mappings) if image.exists?
          end
        end

        def delete
          ec2_client.delete_launch_template_versions(
            launch_template_id: id,
            versions: [version.to_s]
          )
        end
      end
    end
  end
end
