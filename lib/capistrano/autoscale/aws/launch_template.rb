# frozen_string_literal: true

module Capistrano
  module Autoscale
    module AWS
      class LaunchTemplate < Base
        attr_reader :id, :name, :version

        def initialize(id, name, version)
          @id = id
          @name = name
          @version = version
        end

        def update(ami, description: nil)
          latest = ec2_client.create_launch_template_version(
            launch_template_data: { image_id: ami.id },
            launch_template_id: @id,
            source_version: @version,
            version_description: description
          ).launch_template_version

          self.class.new(
            latest&.launch_template_id,
            latest&.launch_template_name,
            latest&.version_number
          )
        end
      end
    end
  end
end
