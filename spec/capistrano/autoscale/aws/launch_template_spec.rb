# frozen_string_literal: true

describe Capistrano::Autoscale::AWS::LaunchTemplate do
  subject { Capistrano::Autoscale::AWS::LaunchTemplate.new 'test-lt', 'test', 2, false, 'ami-aabbccdd' }

  before do
    webmock :post, %r{ec2.(.*).amazonaws.com\/\z} => 'CreateLaunchTemplateVersion.200.xml',
      with: Hash[body: /Action=CreateLaunchTemplateVersion/]
  end

  describe '#initialize' do
    it 'sets the id' do
      expect(subject.id).to eq 'test-lt'
    end

    it 'sets the name' do
      expect(subject.name).to eq 'test'
    end

    it 'sets the version' do
      expect(subject.version).to eq 2
    end
  end

  describe '#update' do
    it 'hits the CreateLaunchTemplateVersion API' do
      subject.update double(:ami, id: 'ami-123')
      expect(WebMock)
        .to have_requested(:post, /ec2/)
        .with(body: /Action=CreateLaunchTemplateVersion/)
    end

    it 'creates a new launch template from the given AMI' do
      subject.update double(:ami, id: 'ami-123')
      expect(WebMock)
        .to have_requested(:post, /ec2/)
        .with(body: /LaunchTemplateData.ImageId=ami-123/)
    end

    it 'uses itself as the source' do
      subject.update double(:ami, id: 'ami-123')
      expect(WebMock)
        .to have_requested(:post, /ec2/)
        .with(body: /LaunchTemplateId=test-lt&SourceVersion=2/)
    end

    it 'returns a new launch template' do
      launch_template = subject.update double(:ami, id: 'ami-123')
      expect(launch_template.id).to eq 'lt-1234567890'
      expect(launch_template.name).to eq 'autoscale-test'
      expect(launch_template.version).to eq 123
    end
  end

  describe '#previous_versions' do
    it 'returns previous versions based on current version' do
      webmock :post, %r{ec2.(.*).amazonaws.com\/\z} => 'DescribeLaunchTemplateVersions.200.xml',
        with: Hash[body: /Action=DescribeLaunchTemplateVersions/]

      expect(subject.version).to eq 2

      previous_versions = subject.previous_versions
      expect(previous_versions.size).to eq 1
      expect(previous_versions.first.version).to eq 1
    end
  end

  describe '#ami' do
    it 'returns the associated AMI' do
      webmock :post, %r{ec2.(.*).amazonaws.com\/\z} => 'DescribeImages.200.xml',
        with: Hash[body: /Action=DescribeImages/]

      ami = subject.ami
      expect(ami.id).to eq 'ami-1234567890'
    end
  end

  describe '#delete' do
    before do
      webmock :post, /ec2/ => 201, with: Hash[body: /Action=DeleteLaunchTemplateVersions/]
    end

    it 'calls the delete AMI API' do
      subject.delete
      expect(WebMock)
        .to have_requested(:post, /ec2/)
        .with body: /Action=DeleteLaunchTemplateVersions&LaunchTemplateId=test-lt/
    end
  end
end
