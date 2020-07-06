# frozen_string_literal: true

require 'capistrano/doctor/output_helpers'

module Capistrano
  module Autoscale
    module Logger
      include Capistrano::Doctor::OutputHelpers

      PREFIX_TEXT = 'Autoscaling'

      def info(message)
        $stdout.puts "#{info_prefix}: #{message}"
      end

      def error(message)
        $stderr.puts "#{error_prefix}: #{message}"
      end

      private

      def info_prefix
        @info_prefix ||= cyan(PREFIX_TEXT)
      end

      def error_prefix
        @error_prefix ||= red(PREFIX_TEXT)
      end

      def cyan(text)
        color_text text, :cyan
      end

      def red(text)
        color_text text, :red
      end

      def color_text(text, coloring)
        color.colorize text, coloring
      end
    end
  end
end
