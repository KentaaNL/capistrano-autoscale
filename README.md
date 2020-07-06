# Capistrano Autoscale

[![Build Status](https://travis-ci.org/KentaaNL/capistrano-autoscale.svg?branch=master)](https://travis-ci.org/KentaaNL/capistrano-autoscale)

This is a fork of [lserman/capistrano-elbas](https://github.com/lserman/capistrano-elbas), with several improvements.

Capistrano-autoscale was written to ease the deployment of Rails applications to AWS Auto Scaling
Groups. During your Capistrano deployment, capistrano-autoscale will:

- Suspend Launch & Terminate processes on the Auto Scaling Group.
- Deploy your code to each running instance connected to a given Auto Scaling Group.
- After deployment, create an AMI from one of the running instances.
- Update the Auto Scaling Group's launch template with the AMI ID.
- Delete any outdated AMIs created by previous deployments.
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

You can configure the prefixes that AMI names will get and add custom tags to AMIs and snapshots using the following options:

```ruby
set :aws_autoscale_ami_prefix, "my-ami"
set :aws_autoscale_ami_tags, { "Environment" => "Sandbox" }
set :aws_autoscale_snapshot_tags, { "Environment" => "Sandbox" }
```

## Usage

Instead of using Capistrano's `server` method, use `autoscale` instead in
`deploy/<environment>.rb` (replace &lt;environment&gt; with your environment). Provide
the name of your AutoScale group instead of a hostname:

```ruby
autoscale 'my-autoscale-group', user: 'apps', roles: [:app, :web, :db]
```

Run `cap production deploy`.

Note: Your Auto Scaling Group must use Launch Templates as opposed to Launch
Configurations. This allows capistrano-autoscale to simply create a new Launch Template version
with the new AMI ID after a deployment. Failure to use a
Launch Template will result in a `Capistrano::Autoscale::Errors::NoLaunchTemplate` error.

### Customizing Server Properties

You can pass a block to `autoscale` and return properties for any specific server.
The block accepts the server and the server's index as arguments.

For example, if you want to apply the `:db` role to only the first server:

```ruby
autoscale 'my-autoscale-group', roles: [:app, :web] do |server, i|
  { roles: [:app, :web, :db] } if i == 0
end
```

Returning `nil` from this block will cause the server to use the properties
passed to `autoscale`.

Returning anything but `nil` will override the entire properties hash (as
opposed to merging the two hashes together).
