# frozen_string_literal: true

module Capistrano
  module Autoscale
    module AWS
      module Taggable
        def tag(key, value)
          @tags ||= {}
          aws_counterpart.create_tags tags: [{ key: key, value: value }]
          @tags[key] = value
        end

        def tags
          @tags || {}
        end
      end
    end
  end
end
