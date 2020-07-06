# frozen_string_literal: true

describe Capistrano::Autoscale::AWS::Taggable do
  TestTaggable = Class.new do
    include Capistrano::Autoscale::AWS::Taggable

    def aws_counterpart
      @aws_counterpart ||= ::Aws::EC2::Instance.new 'test'
    end
  end

  let(:subject) { TestTaggable.new }

  before do
    webmock :post, %r{amazonaws.com\/\z} => 'CreateTags.200.xml',
      with: Hash[body: /Action=CreateTags/]
  end

  describe '#tag' do
    it 'hits the CreateTags API' do
      subject.tag 'test', 'true'
      expect(WebMock)
        .to have_requested(:post, /aws/)
        .with body: /Action=CreateTags/
    end

    it 'sends the resource, key, and value' do
      subject.tag 'test', 'true'
      expect(WebMock)
        .to have_requested(:post, /aws/)
        .with body: /ResourceId.1=test&Tag.1.Key=test&Tag.1.Value=true/
    end
  end
end
