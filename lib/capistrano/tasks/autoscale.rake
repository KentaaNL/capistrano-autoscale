# frozen_string_literal: true

namespace :load do
  task :defaults do
    set_if_empty :aws_autoscale_ami_prefix, fetch(:stage)
    set_if_empty :aws_autoscale_ami_tags, {}
    set_if_empty :aws_autoscale_snapshot_tags, {}
    set_if_empty :aws_autoscale_suspend_processes, true
  end
end

namespace :autoscale do
  task :suspend do
    asg = Capistrano::Autoscale::AWS::AutoscaleGroup.new(fetch(:aws_autoscale_group_name))
    info 'Suspending Auto Scaling processes...'
    asg.suspend
  end

  task :resume do
    asg = Capistrano::Autoscale::AWS::AutoscaleGroup.new(fetch(:aws_autoscale_group_name))
    info 'Resuming Auto Scaling processes...'
    asg.resume
  end

  task :deploy do
    asg = Capistrano::Autoscale::AWS::AutoscaleGroup.new(fetch(:aws_autoscale_group_name))

    info 'Creating AMI from a running instance...'
    ami = Capistrano::Autoscale::AWS::AMI.create(asg.instances.running.sample, prefix: fetch(:aws_autoscale_ami_prefix))
    ami.deploy_group = asg.name
    ami.deploy_id = env.timestamp.to_i.to_s

    fetch(:aws_autoscale_ami_tags).each { |key, value| ami.tag(key, value) }

    ami.snapshots.each do |snapshot|
      fetch(:aws_autoscale_snapshot_tags).each { |key, value| snapshot.tag(key, value) }
    end

    info "Created AMI: #{ami.id}"

    info 'Updating Launch Template with the new AMI...'
    launch_template = asg.launch_template.update(ami, description: revision_log_message)
    info "Updated Launch Template, latest version = #{launch_template.version}"

    info 'Cleaning up old AMIs...'
    ami.ancestors.each do |ancestor|
      info "Deleting old AMI: #{ancestor.id}"
      ancestor.delete
    end
  end
end
