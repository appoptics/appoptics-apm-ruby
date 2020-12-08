# Copyright (c) 2016 SolarWinds, LLC.
# All rights reserved.

# This file is used to initialize the background Sidekiq
# process launched in our test suite.

ENV['BUNDLE_GEMFILE'] = Dir.pwd + "/gemfiles/libraries.gemfile"


require 'rubygems'
require 'bundler/setup'
require 'appoptics_apm'

require_relative '../jobs/sidekiq/activejob_worker_job.rb'

ENV["RACK_ENV"] = "test"
ENV["APPOPTICS_GEM_TEST"] = "true"
ENV["APPOPTICS_GEM_VERBOSE"] = "true"

Bundler.require(:default, :test)
# Redis.exists_returns_integer = false # this will be removed in redis >= 5.0

# Configure AppOpticsAPM
AppOpticsAPM::Config[:tracing_mode] = :enabled
AppOpticsAPM::Config[:sample_rate] = 1000000
# AppOpticsAPM.logger.level = Logger::DEBUG
AppOpticsAPM.logger.level = Logger::FATAL
