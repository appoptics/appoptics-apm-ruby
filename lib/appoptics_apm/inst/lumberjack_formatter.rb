# Copyright (c) 2019 SolarWinds, LLC.
# All rights reserved.

require_relative 'logger_formatter'

if AppOpticsAPM.loaded && defined?(Lumberjack::Formatter)
  module Lumberjack
    class Formatter
      if RUBY_VERSION >= '2.3'
        prepend AppOpticsAPM::Logger::Formatter
      else
        include AppOpticsAPM::Logger::Formatter
      end
    end
  end
end

