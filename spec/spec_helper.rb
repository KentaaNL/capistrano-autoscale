# frozen_string_literal: true

ENV['AWS_REGION'] = 'us-east-1'
ENV['AWS_ACCESS_KEY_ID'] = 'test-access'
ENV['AWS_SECRET_ACCESS_KEY'] = 'test-secret'

require 'capistrano/autoscale'

require 'webmock'
require 'webmock/rspec'

WebMock.disable_net_connect!

# Hack for webmock-rspec-helper
Rails = Class.new do
  def self.root
    Pathname.new(__dir__).join('..')
  end
end

require 'webmock-rspec-helper'

RSpec.configure do |c|
  c.include Capistrano::DSL
  c.include Capistrano::Autoscale::DSL
end
