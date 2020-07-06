# frozen_string_literal: true

module Capistrano
  module Autoscale
    module AWS
      class Base
        include Capistrano::DSL

        def ec2_client
          @ec2_client ||= ::Aws::EC2::Client.new(aws_options)
        end

        def aws_options
          options = {}
          options[:region] = aws_region if aws_region
          options[:credentials] = aws_credentials if aws_credentials.set?
          options
        end

        def aws_credentials
          fetch :aws_credentials, ::Aws::Credentials.new(aws_access_key_id, aws_secret_access_key)
        end

        def aws_access_key_id
          fetch :aws_access_key_id
        end

        def aws_secret_access_key
          fetch :aws_secret_access_key
        end

        def aws_region
          fetch :aws_region
        end
      end
    end
  end
end
