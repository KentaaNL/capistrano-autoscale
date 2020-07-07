# frozen_string_literal: true

namespace :load do
  task :defaults do
    set_if_empty :aws_autoscale_group_names, []
    set_if_empty :aws_autoscale_ami_prefix, fetch(:stage)
    set_if_empty :aws_autoscale_ami_tags, {}
    set_if_empty :aws_autoscale_snapshot_tags, {}
    set_if_empty :aws_autoscale_suspend_processes, true
    set_if_empty :aws_autoscale_cleanup_old_versions, true
    set_if_empty :aws_autoscale_keep_versions, fetch(:keep_releases)
  end
end

namespace :autoscale do
  task :suspend do
    info 'Suspending Auto Scaling processes...'

    fetch(:aws_autoscale_group_names).each do |name|
      asg = Capistrano::Autoscale::AWS::AutoscaleGroup.new(name)
      asg.suspend
    end
  end

  task :resume do
    info 'Resuming Auto Scaling processes...'

    fetch(:aws_autoscale_group_names).each do |name|
      asg = Capistrano::Autoscale::AWS::AutoscaleGroup.new(name)
      asg.resume
    end
  end

  task :update do
    fetch(:aws_autoscale_group_names).each do |name|
      set :aws_autoscale_group_name, name

      info "Auto Scaling Group: #{name}"

      invoke! 'autoscale:create_ami'
      invoke! 'autoscale:update_launch_template'
      invoke! 'autoscale:cleanup'
    end
  end

  task :create_ami do
    asg = Capistrano::Autoscale::AWS::AutoscaleGroup.new(fetch(:aws_autoscale_group_name))

    info 'Creating AMI from a running instance...'
    ami = Capistrano::Autoscale::AWS::AMI.create(asg.instances.running.sample, prefix: fetch(:aws_autoscale_ami_prefix))
    ami.create_tags(asg.name)

    set :aws_autoscale_ami, ami

    info "Created AMI: #{ami.id}"
  end

  task update_launch_template: [:create_ami] do
    asg = Capistrano::Autoscale::AWS::AutoscaleGroup.new(fetch(:aws_autoscale_group_name))
    ami = fetch(:aws_autoscale_ami)

    info 'Updating Launch Template with the new AMI...'
    launch_template = asg.launch_template.update(ami, description: revision_log_message)

    set :aws_autoscale_launch_template, launch_template

    info "Updated Launch Template, latest version = #{launch_template.version}"
  end

  task cleanup: [:create_ami, :update_launch_template] do
    next unless fetch(:aws_autoscale_cleanup_old_versions)

    launch_template = fetch(:aws_autoscale_launch_template)

    info 'Cleaning up old Launch Template versions and AMIs...'
    launch_template.previous_versions.drop(fetch(:aws_autoscale_keep_versions)).each do |version|
      next if version.default || version.ami.nil?
      # Only delete templates & AMIs that were tagged by us.
      next if version.ami.deploy_group != fetch(:aws_autoscale_group_name)

      info "Deleting old Launch Template version: #{version.version}"
      if version.delete
        info "Deleting old AMI: #{version.ami.id}"
        version.ami.delete
      end
    end
  end
end
