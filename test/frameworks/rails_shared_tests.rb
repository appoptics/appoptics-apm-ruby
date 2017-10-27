# Copyright (c) 2016 SolarWinds, LLC.
# All rights reserved.

require "minitest_helper"
require 'mocha/mini_test'


  describe "RailsSharedTests" do
    before do
      TraceView.config_lock.synchronize {
        @tm = TraceView::Config[:tracing_mode]
        @sample_rate = TraceView::Config[:sample_rate]
      }
    end

    after do
      TraceView.config_lock.synchronize {
        TraceView::Config[:tracing_mode] = @tm
        TraceView::Config[:sample_rate] = @sample_rate
      }
    end

    it "should NOT trace when tracing is set to :never" do
      TraceView.config_lock.synchronize do
        TraceView::Config[:tracing_mode] = :never
        uri = URI.parse('http://127.0.0.1:8140/hello/world')
        r = Net::HTTP.get_response(uri)

        traces = get_all_traces
        traces.count.must_equal 0
      end
    end

    it "should NOT trace when sample_rate is 0" do
      TraceView.config_lock.synchronize do
        TraceView::Config[:sample_rate] = 0
        uri = URI.parse('http://127.0.0.1:8140/hello/world')
        r = Net::HTTP.get_response(uri)

        traces = get_all_traces
        traces.count.must_equal 0
      end
    end

    it "should NOT trace when there is no context" do
      response_headers = HelloController.action("world").call(
          "REQUEST_METHOD" => "GET",
          "rack.input" => -> {}
      )[1]

      response_headers.key?('X-Trace').must_equal false

      traces = get_all_traces
      traces.count.must_equal 0
    end

    it "should send inbound metrics" do
      test_action, test_url, test_status, test_method, test_error = nil, nil, nil, nil, nil

      TraceView::Span.expects(:createHttpSpan).with do |action, url, _duration, status, method, error|
        test_action = action
        test_url = url
        test_status = status
        test_method = method
        test_error = error
      end.once

      uri = URI.parse('http://127.0.0.1:8140/hello/world')
      Net::HTTP.get_response(uri)

      assert_equal "HelloController.world", test_action
      assert_equal "http://127.0.0.1:8140", test_url
      assert_equal 200, test_status
      assert_equal "GET", test_method
      assert_equal 0, test_error
    end

    it "should send inbound metrics when not tracing" do
      test_action, test_url, test_status, test_method, test_error = nil, nil, nil, nil, nil
      TraceView.config_lock.synchronize do
        TraceView::Config[:tracing_mode] = :never
        TraceView::Span.expects(:createHttpSpan).with do |action, url, _duration, status, method, error|
          test_action = action
          test_url = url
          test_status = status
          test_method = method
          test_error = error
        end.once

        uri = URI.parse('http://127.0.0.1:8140/hello/world')
        Net::HTTP.get_response(uri)
      end

      assert_equal "HelloController.world", test_action
      assert_equal "http://127.0.0.1:8140", test_url
      assert_equal 200, test_status
      assert_equal "GET", test_method
      assert_equal 0, test_error
    end

    it "should send metrics for 500 errors" do
      test_action, test_url, test_status, test_method, test_error = nil, nil, nil, nil, nil

      TraceView::Span.expects(:createHttpSpan).with do |action, url, _duration, status, method, error|
        test_action = action
        test_url = url
        test_status = status
        test_method = method
        test_error = error
      end.once

      uri = URI.parse('http://127.0.0.1:8140/hello/servererror')
      Net::HTTP.get_response(uri)

      assert_equal "HelloController.servererror", test_action
      assert_equal "http://127.0.0.1:8140", test_url
      assert_equal 500, test_status
      assert_equal "GET", test_method
      assert_equal 1, test_error
    end
  end
