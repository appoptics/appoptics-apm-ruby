# Copyright (c) 2016 SolarWinds, LLC.
# All rights reserved.

module AppOptics
  module Grape
    module API
      def self.extended(klass)
        ::AppOptics::Util.class_method_alias(klass, :inherited, ::Grape::API)
      end

      def inherited_with_appoptics(subclass)
        inherited_without_appoptics(subclass)

        subclass.use ::AppOptics::Rack
      end
    end

    module Endpoint
      def self.included(klass)
        ::AppOptics::Util.method_alias(klass, :run, ::Grape::Endpoint)
      end

      def run_with_appoptics(*args)
        # Report Controller/Action and Transaction as best possible
        report_kvs = {}

        if route && route.pattern
          action = route.pattern.origin
          version = route.pattern.capture[:version]
          action.gsub!(/:version/, version.first) if version
        else
          action = args.empty? ? env['PATH_INFO'] : args[0]['PATH_INFO']
        end

        report_kvs[:Controller] = options[:for]
        report_kvs[:Action] = "#{env['REQUEST_METHOD']}#{action}"

        env['appoptics.transaction'] = [report_kvs[:Controller], report_kvs[:Action]].join('.')

        ::AppOptics::API.log_entry('grape', report_kvs)

        run_without_appoptics(*args)
      ensure
        ::AppOptics::API.log_exit('grape')
      end
    end

    module Middleware
      module Error
        def self.included(klass)
          ::AppOptics::Util.method_alias(klass, :error_response, ::Grape::Middleware::Error)
        end

        def error_response_with_appoptics(error = {})
          status, headers, body = error_response_without_appoptics(error)

          if AppOptics.tracing?
            # Since Grape uses throw/catch and not Exceptions, we manually log
            # the error here.
            kvs = {}
            kvs[:ErrorClass] = 'GrapeError'
            kvs[:ErrorMsg] = error[:message] ? error[:message] : "No message given."
            kvs[:Backtrace] = ::AppOptics::API.backtrace if AppOptics::Config[:grape][:collect_backtraces]

            ::AppOptics::API.log(nil, 'error', kvs)

            # Since calls to error() are handled similar to abort in Grape.  We
            # manually log the rack exit here since the original code won't
            # be returned to
            xtrace = AppOptics::API.log_end('rack', :Status => status)

            if headers && AppOptics::XTrace.valid?(xtrace)
              unless defined?(JRUBY_VERSION) && AppOptics.is_continued_trace?
                headers['X-Trace'] = xtrace if headers.is_a?(Hash)
              end
            end
          end

          [status, headers, body]
        end
      end
    end
  end
end

if defined?(::Grape)
  require 'appoptics/inst/rack'

  AppOptics.logger.info "[appoptics/loading] Instrumenting Grape" if AppOptics::Config[:verbose]

  AppOptics::Inst.load_instrumentation

  ::AppOptics::Util.send_extend(::Grape::API,               ::AppOptics::Grape::API)
  ::AppOptics::Util.send_include(::Grape::Endpoint,          ::AppOptics::Grape::Endpoint)
  ::AppOptics::Util.send_include(::Grape::Middleware::Error, ::AppOptics::Grape::Middleware::Error)
end
