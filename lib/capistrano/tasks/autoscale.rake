# frozen_string_literal: true

namespace :load do
  task :defaults do
    set_if_empty :aws_autoscale_group_names, []
    set_if_empty :aws_autoscale_standby_instances, []
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

    fetch(:aws_autoscale_standby_instances).each do |asg, instance|
      info "Instance #{instance.id} exiting standby state..."
      asg.exit_standby(instance)
    end
  end

  task :update do
    fetch(:aws_autoscale_group_names).each do |name|
      set :aws_autoscale_group_name, name

      invoke! 'autoscale:update_auto_scaling_group'
    end
  end

  task :update_auto_scaling_group do
    name = fetch(:aws_autoscale_group_name, ENV['autoscale_group_name'])
    raise ArgumentError, 'No autoscale group name' if name.nil?

    set :aws_autoscale_group_name, name

    info "Auto Scaling Group: #{name}"

    invoke! 'autoscale:create_ami'
    invoke! 'autoscale:update_launch_template'
    invoke! 'autoscale:cleanup'
  end

  task :create_ami do
    asg = Capistrano::Autoscale::AWS::AutoscaleGroup.new(fetch(:aws_autoscale_group_name))
    prefix = asg.ami_prefix || fetch(:aws_autoscale_ami_prefix)

    info 'Selecting instance to create AMI from...'
    instance = asg.instances_in_service.running.sample

    if instance
      info "Instance #{instance.id} entering standby state..."
      asg.enter_standby(instance)

      standby_instances = fetch(:aws_autoscale_standby_instances)
      standby_instances << [asg, instance]

      info "Creating AMI from #{instance.id} "

      ami = Capistrano::Autoscale::AWS::AMI.create(instance, prefix: prefix)
      ami.create_tags(asg.name)

      set :aws_autoscale_ami, ami

      info "Created AMI: #{ami.id}"

      unless asg.suspended?
        info "Instance #{instance.id} exiting standby state..."
        asg.exit_standby(instance)
      end
    else
      error 'Unable to create AMI. No instance with a valid state was found in the Auto Scaling group.'
    end
  end

  task update_launch_template: [:create_ami] do
    asg = Capistrano::Autoscale::AWS::AutoscaleGroup.new(fetch(:aws_autoscale_group_name))
    ami = fetch(:aws_autoscale_ami)
    next if ami.nil?

    info 'Updating Launch Template with the new AMI...'
    launch_template = asg.launch_template.update(ami, description: revision_log_message)

    set :aws_autoscale_launch_template, launch_template

    info "Updated Launch Template, latest version = #{launch_template.version}"
  end

  task cleanup: [:create_ami, :update_launch_template] do
    next unless fetch(:aws_autoscale_cleanup_old_versions)

    launch_template = fetch(:aws_autoscale_launch_template)
    next if launch_template.nil?

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
