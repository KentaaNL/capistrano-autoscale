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
          @tags ||= aws_counterpart.tags.map { |tag| [tag.key, tag.value] }.to_h
        end
      end
    end
  end
end
