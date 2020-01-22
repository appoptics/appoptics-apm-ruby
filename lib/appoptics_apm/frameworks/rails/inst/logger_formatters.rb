# Copyright (c) 2019 SolarWinds, LLC.
# All rights reserved.

if AppOpticsAPM.loaded && defined?(ActiveSupport::Logger::SimpleFormatter)
  module ActiveSupport
    class Logger
      class SimpleFormatter
        if RUBY_VERSION >= '2.3'
          # even though SimpleFormatter inherits from Logger,
          # this will not append traceId twice,
          # because SimpleFormatter#call does not call super
          prepend AppOpticsAPM::Logger::Formatter
        else
          # include AppOpticsAPM::Logger::Formatter not working because
          # SimpleFormatter inherits from Logger and the methods are already
          # aliased, so we need to do something to explicitely use :call from
          # SimpleFormatter
          unless self.method_defined?(:call_w_appoptics)
            def call_w_appoptics(severity, time, progname, msg)
              return call_original(severity, time, progname, msg) if AppOpticsAPM::Config[:log_traceId] == :never

              msg = insert_trace_id(msg)
              call_original(severity, time, progname, msg)
            end

            alias_method :call_original, :call
            alias_method :call, :call_w_appoptics
          end
        end
      end
    end
  end
end


if AppOpticsAPM.loaded && defined?(ActiveSupport::TaggedLogging::Formatter)
  module ActiveSupport
    module TaggedLogging
      module Formatter
        # TODO figure out ancestors situation
        if RUBY_VERSION >= '2.3'
          prepend AppOpticsAPM::Logger::Formatter
        else
          include AppOpticsAPM::Logger::Formatter
        end
      end
    end
  end
end
