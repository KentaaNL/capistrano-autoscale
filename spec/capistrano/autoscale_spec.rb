# frozen_string_literal: true

describe '#autoscale' do
  before do
    Capistrano::Configuration.reset!
    Rake::Task.define_task('deploy') {}
    Rake::Task.define_task('deploy:failed') {}
    invoke! 'load:defaults'

    webmock :post, %r{autoscaling.(.*).amazonaws.com\/\z} => 'DescribeAutoScalingGroups.200.xml',
      with: Hash[body: /Action=DescribeAutoScalingGroups/]
  end

  context 'one server' do
    before do
      webmock :post, %r{ec2.(.*).amazonaws.com\/\z} => 'DescribeInstances.200.xml',
        with: Hash[body: /Action=DescribeInstances/]
    end

    it 'adds the server hostname' do
      autoscale 'test-asg'
      expect(env.servers.count).to eq 1
      expect(env.servers.first.hostname).to eq '10.0.0.12'
    end

    it 'passes along the properties' do
      autoscale 'test-asg', roles: [:db], primary: true
      expect(env.servers.first.properties.roles).to match_array [:db]
      expect(env.servers.first.properties.primary).to eq true
    end
  end

  context 'multiple servers' do
    before do
      webmock :post, %r{ec2.(.*).amazonaws.com\/\z} => 'DescribeInstances_MultipleRunning.200.xml',
        with: Hash[body: /Action=DescribeInstances/]
    end

    it 'adds multiple server hostnames' do
      autoscale 'test-asg'
      expect(env.servers.count).to eq 2
      expect(env.servers.map(&:hostname)).to match_array ['10.0.0.13', '10.0.0.14']
    end

    it 'passes along the properties' do
      autoscale 'test-asg', roles: [:db], primary: true
      count = 0
      env.servers.each do |server|
        count += 1
        expect(server.properties.roles).to match_array [:db]
        expect(server.properties.primary).to eq true
      end
      expect(count).to eq 2
    end

    it 'passes primary roles to the first server' do
      autoscale 'test-asg', roles: [:web], primary_roles: [:web, :db]

      expect(env.servers.to_a[0].properties.roles).to match_array [:web, :db]
      expect(env.servers.to_a[1].properties.roles).to match_array [:web]
    end
  end

  context 'multiple autoscaling groups' do
    before do
      webmock :post, %r{ec2.(.*).amazonaws.com\/\z} => 'DescribeInstances_MultipleRunning.200.xml',
        with: Hash[body: /Action=DescribeInstances/]
    end

    it 'adds multiple server hostnames' do
      autoscale 'test-asg'
      autoscale 'test-asg2'

      expect(env.servers.count).to eq 2
      expect(env.servers.map(&:hostname)).to match_array ['10.0.0.13', '10.0.0.14']
    end
  end

  context 'no servers' do
    before do
      webmock :post, %r{ec2.(.*).amazonaws.com\/\z} => 'DescribeInstances_Empty.200.xml',
        with: Hash[body: /Action=DescribeInstances/]
    end

    it 'logs as an error' do
      expect { autoscale 'test-asg' }.to output.to_stderr
    end
  end
end
