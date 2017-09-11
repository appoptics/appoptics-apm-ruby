# Welcome to the TraceView Ruby Gem

The traceview gem provides [TraceView](https://traceview.solarwinds.com/) performance instrumentation for Ruby.

![Ruby TraceView](http://docs.traceview.solarwinds.com/images/ruby_readme/oboe-ruby-header.png)

It has the ability to report performance metrics on an array of libraries, databases and frameworks such as Rails, Mongo, Memcache, ActiveRecord, Cassandra, Rack, Resque [and more](http://docs.traceview.solarwinds.com/Instrumentation/ruby.html#ruby-support-matrix).

It requires a [TraceView](https://traceview.solarwinds.com/) account to view metrics.  Get yours, [it's free](https://traceview.solarwinds.com/TraceView/Signup).

[![Gem Version](https://badge.fury.io/rb/traceview.png)](https://badge.fury.io/rb/traceview)
[![Build Status](https://travis-ci.org/tracelytics/ruby-traceview.png?branch=master)](https://travis-ci.org/tracelytics/ruby-traceview)
[![Code Climate](https://codeclimate.com/github/tracelytics/ruby-traceview.png)](https://codeclimate.com/github/tracelytics/ruby-traceview)

_Note: The repository name has been changed to ruby-traceview.  Please update your github remotes with `git remote set-url origin git@github.com:tracelytics/ruby-traceview.git`._

# Installation

_Before installing the gem below, make sure that you have the [base packages](http://docs.traceview.solarwinds.com/TraceView/install-instrumentation.html#install-base-packages) installed on your host first._

The traceview gem is [available on Rubygems](https://rubygems.org/gems/traceview) and can be installed with:

```bash
gem install traceview
```

or added to _the end_ of your bundle Gemfile and running `bundle install`:

```ruby
gem 'traceview'
```

# Running

## Rails

![Ruby on Rails](http://docs.traceview.solarwinds.com/images/ruby_readme/rails.png)

No special steps are needed to instrument Ruby on Rails.  Once part of the bundle, the traceview gem will automatically detect Rails and instrument on stack initialization.

*Note: You will still need to decide on your `tracing_mode` depending on whether you are running with an instrumented Apache or nginx in front of your Rails stack.  See below for more details.*

### The Install Generator

The traceview gem provides a Rails generator used to seed an initializer where you can configure and control `tracing_mode` and [other options](http://docs.traceview.solarwinds.com/Instrumentation/ruby.html#configuring-instrumentation).

To run the install generator run:

```bash
bundle exec rails generate traceview:install
```

After the prompts, this will create an initializer: `config/initializers/traceview.rb`.

## Sinatra

![Sinatra](http://docs.traceview.solarwinds.com/images/ruby_readme/sinatra.png)

You can instrument your Sinatra application by adding the following code to your `config.ru` Rackup file:

```ruby
# If you're not using Bundler.require.  Make sure this is done
# after the Sinatra require directive.
require 'traceview'

# You may want to replace the TraceView.logger with whichever logger you are using
# TraceView.logger = Sinatra.logger
```

Make sure that the traceview gem is loaded _after_ Sinatra either by listing `gem 'traceview'` after Sinatra in your Gemfile or calling the `require 'traceview'` directive after Sinatra is loaded.

With this, the traceview gem will automatically detect Sinatra on boot and instrument key components.

## Padrino

![Padrino](http://docs.traceview.solarwinds.com/images/ruby_readme/padrino.png)

As long as the traceview gem is in your `Gemfile` (inserted after the `gem 'padrino'` directive) and you are calling `Bundler.require`, the traceview gem will automatically instrument Padrino applications.

If you need to set `TraceView::Config` values on stack boot, you can do so by adding the following
to your `config/boot.rb` file:

```ruby
Padrino.before_load do
  # Verbose output of instrumentation initialization
  # TraceView::Config[:verbose] = true
end
```

## Grape

![Grape](http://docs.traceview.solarwinds.com/images/ruby_readme/grape.png)

You can instrument your Grape application by adding the following code to your `config.ru` Rackup file:

```ruby
    # If you're not using Bundler.require.  Make sure this is done
    # after the Grape require directive.
    require 'traceview'

    ...

    class App < Grape::API
      use TraceView::Rack
    end
```

Make sure that the traceview gem is loaded _after_ Grape either by listing `gem 'traceview'` after Grape in your Gemfile or calling the `require 'traceview'` directive after Grape is loaded.

You must explicitly tell your Grape application to use TraceView::Rack for tracing to occur.

## Custom Ruby Scripts & Applications

The traceview gem has the ability to instrument any arbitrary Ruby application or script.

```ruby
require 'rubygems'
require 'bundler'

Bundler.require

require 'traceview'
```

From here, you can use the Tracing API to instrument areas of code using `TraceView::API.start_trace` (see below).  If you prefer to instead dive directly into code, take a look at [this example](https://gist.github.com/pglombardo/8550713) of an instrumented Ruby script.

Once inside of the `TraceView::API.start_trace` block, performance metrics will be automatically collected for all supported libraries and gems (Redis, Mongo, ActiveRecord etc..).

## Other

You can send deploy notifications to TraceView and have the events show up on your dashboard.  See: [Capistrano Deploy Notifications with tlog](http://docs.traceview.solarwinds.com/Instrumentation/ruby.html#report-deploy-notifications)

# Custom Tracing

You can add even more visibility into any part of your application or scripts by adding custom instrumentation.  If you want to see the performance of an existing method see Method Profiling.  To trace blocks of code see the Tracing API.

## The Tracing API

You can instrument any arbitrary block of code using `TraceView::API.trace`.  The code and any supported calls for libraries that we support, will automatically get traced and reported to your dashboard.

```ruby
# layer_name will show up in the TraceView app dashboard
layer_name = 'subsystemX'

# report_kvs are a set of information Key/Value pairs that are sent to
# TraceView dashboard along with the performance metrics.  These KV
# pairs are used to report request, environment and/or client specific
# information.

report_kvs = {}
report_kvs[:mykey] = @client.id

TraceView::API.trace(layer_name, report_kvs) do
  # the block of code to be traced
end
```

`TraceView::API.trace` is used within the context of a request.  It will follow the upstream state of the request being traced.  i.e. the block of code will only be traced when the parent request is being traced.

This tracing state of a request can also be queried by using `TraceView.tracing?`.

If you need to instrument code outside the context of a request (such as a cron job, background job or an arbitrary ruby script), use `TraceView::API.start_trace` instead which will initiate new traces based on configuration and probability (based on the sample rate).

Find more details in the [RubyDoc page](http://rdoc.info/gems/traceview/TraceView/API/Tracing) or in [this example](https://gist.github.com/pglombardo/8550713) on how to use the Tracing API in an independent Ruby script.

## Tracing Methods

With TraceView, you can profile any method in your application or even in the Ruby language using `TraceView::API.profile_method`.

If, for example, you wanted to see the performance for the `Array::sort`, you could simply call the following in your startup code:

```
TraceView::API.profile_method(Array, :sort)
```

For full documentation, options and reporting custom KVs, see our documentation on [method profiling](http://docs.traceview.solarwinds.com/Instrumentation/ruby.html#ruby-function-profiling).

# Support

If you find a bug or would like to request an enhancement, feel free to file an issue.  For all other support requests, see our [support portal](https://tracelytics.freshdesk.com).

# Contributing

You are obviously a person of great sense and intelligence.  We happily appreciate all contributions to the traceview gem whether it is documentation, a bug fix, new instrumentation for a library or framework or anything else we haven't thought of.

We welcome you to send us PRs.  We also humbly request that any new instrumentation submissions have corresponding tests that accompany them.  This way we don't break any of your additions when we (and others) make changes after the fact.

## Developer Resources

We have made a large effort to expose as much technical information as possible to assist developers wishing to contribute to the traceview gem.  Below is a good source for information and help for developers:

* The [TraceView Knowledge Base](http://docs.traceview.solarwinds.com/) has a large collection of technical articles or, if needed, you can submit a support request directly to the team.

If you have any questions or ideas, don't hesitate to contact us anytime.

## Layout of the Gem

The traceview gem uses a standard gem layout.  Here are the notable directories.

    lib/traceview/inst               # Auto load directory for various instrumented libraries
    lib/traceview/frameworks         # Framework instrumentation directory
    lib/traceview/frameworks/rails   # Files specific to Rails instrumentation
    lib/rails                        # A Rails required directory for the Rails install generator
    lib/api                          # The TraceView Tracing API: layers, logging, profiling and tracing
    ext/oboe_metal                   # The Ruby c extension that links against the system liboboe library

## Building the Gem

The traceview gem is built with the standard `gem build` command passing in the gemspec:

```bash
gem build traceview.gemspec
```

## Writing Custom Instrumentation

Custom instrumentation for a library, database or other service can be authored fairly easily.  Generally, instrumentation of a library is done by wrapping select operations of that library and timing their execution using the TraceView Tracing API which then reports the metrics to the users' TraceView dashboard.

Here, I'll use a stripped down version of the Dalli instrumentation (`lib/traceview/inst/dalli.rb`) as a quick example of how to instrument a client library (the dalli gem).

The Dalli gem nicely routes all memcache operations through a single `perform` operation.  Wrapping this method allows us to capture all Dalli operations called by an application.

First, we define a module (TraceView::Inst::Dalli) and our own custom `perform_with_traceview` method that we will use as a wrapper around Dalli's `perform` method.  We also declare an `included` method which automatically gets called when this module is included by another.  See ['included' Ruby reference documentation](https://www.omniref.com/ruby/2.2.1/symbols/Module/included).

```ruby
module TraceView
  module Inst
    module Dalli
      include TraceView::API::Memcache

      def self.included(cls)
        cls.class_eval do
          if ::Dalli::Client.private_method_defined? :perform
            alias perform_without_traceview perform
            alias perform perform_with_traceview
          end
        end
      end

      def perform_with_traceview(*all_args, &blk)
        op, key, *args = *all_args

        if TraceView.tracing?
          opts = {}
          opts[:KVOp] = op
          opts[:KVKey] = key

          TraceView::API.trace('memcache', opts || {}) do
            result = perform_without_traceview(*all_args, &blk)
            if op == :get and key.class == String
                TraceView::API.log('memcache', 'info', { :KVHit => memcache_hit?(result) })
            end
            result
          end
        else
          perform_without_traceview(*all_args, &blk)
        end
      end
    end
  end
end
```

Second, we tail onto the end of the instrumentation file a simple `::Dalli::Client.module_eval` call to tell the Dalli module to include our newly defined instrumentation module.  Doing this will invoke our previously defined `included` method.

```ruby
if defined?(Dalli) and TraceView::Config[:dalli][:enabled]
  ::Dalli::Client.module_eval do
    include TraceView::Inst::Dalli
  end
end
```

Third, in our wrapper method, we capture the arguments passed in, collect the operation and key information into a local hash and then invoke the `TraceView::API.trace` method to time the execution of the original operation.

The `TraceView::API.trace` method calls Dalli's native operation and reports the timing metrics and your custom `report_kvs` up to TraceView servers to be shown on the user's dashboard.

Some other tips and guidelines:

* You can point your Gemfile directly at your cloned traceview gem source by using `gem 'traceview', :path => '/path/to/ruby-traceview'`

* If instrumenting a library, database or service, place your new instrumentation file into the `lib/traceview/inst/` directory.  From there, the traceview gem will detect it and automatically load the instrumentation file.

* If instrumenting a new framework, place your instrumentation file in `lib/traceview/frameworks`.  Refer to the Rails instrumentation for on ideas on how to load the traceview gem correctly in your framework.

* Review other existing instrumentation similar to the one you wish to author.  `lib/traceview/inst/` is a great place to start.

* Depending on the configured `:sample_rate`, not all requests will be traced.  Use `TraceView.tracing?` to determine of this is a request that is being traced.

* Performance is paramount.  Make sure that your wrapped methods don't slow down users applications.

* Include tests with your instrumentation.  See `test/instrumentation/` for some examples of existing instrumentation tests.

## Compiling the C extension

The traceview gem utilizes a C extension to interface with the system `liboboe.so` library.  This system library is installed with the TraceView host packages (tracelyzer, liboboe0, liboboe-dev) and is used to report host and performance metrics from multiple sources (Ruby, Apache, Python etc.) back to TraceView servers.

C extensions are usually built on `gem install` but when working out of a local git repository, it's required that you manually build this C extension for the gem to function.

To make this simpler, we've included a few rake tasks to automate this process:

```bash
rake compile             # Build the gem's c extension
rake distclean           # Remove all built files and extensions
rake recompile           # Rebuild the gem's c extension
```

Note: Make sure you have the development package `liboboe0-dev` installed before attempting to compile the C extension.

```bash
>>$ dpkg -l | grep liboboe
ii  liboboe-dev  1.2.1-trusty1  TraceView common library -- development files
ii  liboboe0     1.2.1-trusty1  Traceview common library
```

See [Installing Base Packages on Debian and Ubuntu](http://docs.traceview.solarwinds.com/TraceView/install-instrumentation.html#debian-and-ubuntu) in the Knowledge Base for details.

To see the code related to the C extension, take a look at `ext/oboe_metal/extconf.rb` for details.

You can read more about Ruby gems with C extensions in the [Rubygems Guides](http://guides.rubygems.org/gems-with-extensions/).

## Running the Tests

![TraceView Ruby Tests](http://docs.traceview.solarwinds.com/images/ruby_readme/tv_ruby_tests.png)

The tests bundled with the gem are implemented using [Minitest](https://github.com/seattlerb/minitest).  The tests are currently used to validate the sanity of the traces generated and basic gem functionality.

After a bundle install, the tests can be run as:

```bash
bundle exec rake test
```

This will run a full end-to-end test suite that covers all supported libraries and databases.  Note that this requires all of the supported software (Cassandra, Memcache, Mongo etc.) to be installed, configured and available.

Since this is overly burdensome for casual users, you can run just the tests that you're interested in.

To run just the tests for the dalli gem trace validation:

```bash
bundle exec rake test TEST=test/instrumentation/dalli_test.rb
```

We humbly request that any submitted instrumentation is delivered with corresponding test coverage.

# License

Copyright (c) 2016 SolarWinds, LLC

Released under the [Librato Open License](http://docs.traceview.solarwinds.com/Instrumentation/librato-open-license.html)
