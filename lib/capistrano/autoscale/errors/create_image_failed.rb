# frozen_string_literal: true

module Capistrano
  module Autoscale
    module Errors
      class CreateImageFailed < StandardError
        attr_reader :image

        def initialize(image)
          @image = image
          super(image.state_reason.message)
        end
      end
    end
  end
end
