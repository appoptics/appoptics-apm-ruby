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
          include AppOpticsAPM::Logger::Formatter
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
        prepend AppOpticsAPM::Logger::Formatter
      end
    end
  end
end
