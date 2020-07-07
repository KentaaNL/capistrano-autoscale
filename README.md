# Capistrano Autoscale

[![Build Status](https://travis-ci.org/KentaaNL/capistrano-autoscale.svg?branch=master)](https://travis-ci.org/KentaaNL/capistrano-autoscale)

This is a fork of [lserman/capistrano-elbas](https://github.com/lserman/capistrano-elbas), with several improvements.

Capistrano-autoscale was written to ease the deployment of Rails applications to AWS Auto Scaling
Groups. During your Capistrano deployment, capistrano-autoscale will:

- Suspend Launch & Terminate processes on the Auto Scaling Group.
- Deploy your code to each running instance connected to a given Auto Scaling Group.
- After deployment, create an AMI from one of the running instances.
- Create a new Launch Template version with the AMI ID based on the current Auto Scaling Group's Launch Template.
- Delete any outdated Launch Template versions, AMIs and snapshots created by previous deployments.
- Resume Launch & Terminate processes on the Auto Scaling Group.

## Installation

Add to Gemfile, then run `bundle`:

`gem 'capistrano-autoscale', require: false, git: 'https://github.com/KentaaNL/capistrano-autoscale.git'`

Add to Capfile:

`require 'capistrano/autoscale'`

## Configuration

Setup AWS credentials:

```ruby
set :aws_access_key_id,     ENV['AWS_ACCESS_KEY_ID']
set :aws_secret_access_key, ENV['AWS_SECRET_ACCESS_KEY']
set :aws_region,            ENV['AWS_REGION']
```

To configure the prefix that AMIs will get (defaults to stage name):

```ruby
set :aws_autoscale_ami_prefix, "my-ami"
```

To add custom tags to AMIs and snapshots you can specify a hash:

```ruby
set :aws_autoscale_ami_tags, { "Environment" => "Sandbox" }
set :aws_autoscale_snapshot_tags, { "Environment" => "Sandbox" }
```

By default, the Launch & Terminate processes will be suspended during deployment. To disable this:

```ruby
set :aws_autoscale_suspend_processes, false
```

After deployment, any outdated Launch Template versions, AMIs and snapshots will be deleted. By default, the number of `keep_releases` will be kept. To change this, set:

```ruby
set :aws_autoscale_cleanup_old_versions, true
set :aws_autoscale_keep_versions, 8
```

## Usage

Instead of using Capistrano's `server` method, use `autoscale` instead in
`deploy/<environment>.rb` (replace &lt;environment&gt; with your environment). Provide
the name of your Auto Scaling group instead of a hostname:

```ruby
autoscale 'my-autoscale-group', user: 'apps', roles: [:app, :web, :db]
```

If you have multiple autoscaling groups to deploy to, specify each of them:

```ruby
autoscale 'app-autoscale-group', user: 'apps', roles: [:app, :web]
autoscale 'worker-autoscale-group', user: 'apps', roles: [:worker]
```

Run `cap production deploy`.

Note: Your Auto Scaling Group must use Launch Templates as opposed to Launch Configurations.
This allows capistrano-autoscale to simply create a new Launch Template version with the new AMI ID after a deployment.
Failure to use a Launch Template will result in a `Capistrano::Autoscale::Errors::NoLaunchTemplate` error.
