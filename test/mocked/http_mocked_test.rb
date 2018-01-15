# Copyright (c) 2016 SolarWinds, LLC.
# All rights reserved.

unless defined?(JRUBY_VERSION)
  require 'minitest_helper'
  require 'mocha/mini_test'
  require 'net/http'

  class HTTPMockedTest < Minitest::Test

    class MockResponse
      def get_fields(x); nil; end
      def code; 200; end
    end

    def setup
      AppOpticsAPM.config_lock.synchronize do
        @sample_rate = AppOpticsAPM::Config[:sample_rate]
      end
    end

    def teardown
      AppOpticsAPM.config_lock.synchronize do
        AppOpticsAPM::Config[:sample_rate] = @sample_rate
        AppOpticsAPM::Config[:blacklist] = []
      end
    end

    # webmock not working, interferes with instrumentation

    def test_tracing_sampling
      Net::HTTP.any_instance.expects(:request_without_appoptics).with do |req, _|
        !req.to_hash['x-trace'].nil? &&
            req.to_hash['x-trace'].first =~ /^2B[0-9,A-F]*01$/
      end.returns(MockResponse.new)

      AppOpticsAPM::API.start_trace('net_http_test') do
        uri = URI('http://127.0.0.1:8101/?q=1')
        Net::HTTP.start(uri.host, uri.port) do |http|
          request = Net::HTTP::Get.new(uri)
          http.request(request)
        end
      end
    end

    def test_tracing_not_sampling
      Net::HTTP.any_instance.expects(:request_without_appoptics).with do |req, _, _|
        !req.to_hash['x-trace'].nil? &&
            req.to_hash['x-trace'].first =~ /^2B[0-9,A-F]*00$/ &&
            req.to_hash['x-trace'].first !~ /^2B0*$/
      end.returns(MockResponse.new)

      AppOpticsAPM.config_lock.synchronize do
        AppOpticsAPM::Config[:sample_rate] = 0
        AppOpticsAPM::API.start_trace('Net::HTTP_test') do
          uri = URI('http://127.0.0.1:8101/?q=1')
          Net::HTTP.start(uri.host, uri.port) do |http|
            request = Net::HTTP::Get.new(uri)
            http.request(request) # Net::HTTPResponse object
          end
        end
      end
    end

    def test_no_xtrace
      Net::HTTP.any_instance.expects(:request_without_appoptics).with do |req, _, _|
        req.to_hash['x-trace'].nil?
      end.returns(MockResponse.new)

      uri = URI('http://127.0.0.1:8101/?q=1')
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Get.new(uri)
        http.request(request) # Net::HTTPResponse object
      end
    end

    def test_blacklisted
      Net::HTTP.any_instance.expects(:request_without_appoptics).with do |req, _, _|
        req.to_hash['x-trace'].nil?
      end.returns(MockResponse.new)

      AppOpticsAPM.config_lock.synchronize do
        AppOpticsAPM::Config.blacklist << '127.0.0.1'
        AppOpticsAPM::API.start_trace('Net::HTTP_tests') do
          uri = URI('http://127.0.0.1:8101/?q=1')
          Net::HTTP.start(uri.host, uri.port) do |http|
            request = Net::HTTP::Get.new(uri)
            http.request(request) # Net::HTTPResponse object
          end
        end
      end
    end

    def test_not_sampling_blacklisted
      Net::HTTP.any_instance.expects(:request_without_appoptics).with do |req, _, _|
        req.to_hash['x-trace'].nil?
      end.returns(MockResponse.new)

      AppOpticsAPM.config_lock.synchronize do
        AppOpticsAPM::Config[:sample_rate] = 0
        AppOpticsAPM::Config.blacklist << '127.0.0.1'
        AppOpticsAPM::API.start_trace('Net::HTTP_tests') do
          uri = URI('http://127.0.0.1:8101/?q=1')
          Net::HTTP.start(uri.host, uri.port) do |http|
            request = Net::HTTP::Get.new(uri)
            http.request(request) # Net::HTTPResponse object
          end
        end
      end
    end
  end
end
