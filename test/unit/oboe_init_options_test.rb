# Copyright (c) 2019 SolarWinds, LLC.
# All rights reserved.

require 'minitest_helper'

describe 'OboeInitOptions' do

  before do
    @env = ENV.to_hash
    @log_level = AppOpticsAPM.logger.level
  end

  after do
    @env.each { |k,v| ENV[k] = v }
    AppOpticsAPM::OboeInitOptions.instance.re_init
    AppOpticsAPM.logger.level = @log_level
  end

  it 'sets all options from ENV vars' do
    ENV['APPOPTICS_SERVICE_KEY'] = 'string_0'
    ENV['APPOPTICS_REPORTER'] = 'udp'
    ENV['APPOPTICS_COLLECTOR'] = 'string_2'
    ENV['APPOPTICS_TRUSTEDPATH'] = 'string_3'
    ENV['APPOPTICS_HOSTNAME_ALIAS'] = 'string_4'
    ENV['APPOPTICS_BUFSIZE'] = '11'
    ENV['APPOPTICS_LOGFILE'] = 'string_5'
    ENV['APPOPTICS_DEBUG_LEVEL'] = '2'
    ENV['APPOPTICS_TRACE_METRICS'] = '3'
    ENV['APPOPTICS_HISTOGRAM_PRECISION'] = '4'
    ENV['APPOPTICS_MAX_TRANSACTIONS'] = '5'
    ENV['APPOPTICS_FLUSH_MAX_WAIT_TIME'] = '6'
    ENV['APPOPTICS_EVENTS_FLUSH_INTERVAL'] = '7'
    ENV['APPOPTICS_EVENTS_FLUSH_BATCH_SIZE'] = '8'
    ENV['APPOPTICS_TOKEN_BUCKET_CAPACITY'] = '9'
    ENV['APPOPTICS_TOKEN_BUCKET_RATE'] = '10'
    ENV['APPOPTICS_REPORTER_FILE_SINGLE'] = 'True'

    AppOpticsAPM::OboeInitOptions.instance.re_init
    options = AppOpticsAPM::OboeInitOptions.instance.array_for_oboe

    options.size.must_equal 17
    options[0].must_equal 'string_4'
    options[1].must_equal 2
    options[2].must_equal 'string_5'
    options[3].must_equal 5
    options[4].must_equal 6
    options[5].must_equal 7
    options[6].must_equal 8
    options[7].must_equal 'file'  # because we are testing
    options[8].must_equal 'string_2'
    options[9].must_equal 'string_0'
    options[10].must_equal 'string_3'
    options[11].must_equal 11
    options[12].must_equal 3
    options[13].must_equal 4
    options[14].must_equal 9
    options[15].must_equal 10
    options[16].must_equal 1
  end

  it 'reads config vars' do
    ENV.delete('APPOPTICS_HOSTNAME_ALIAS')
    ENV.delete('APPOPTICS_DEBUG_LEVEL')
    ENV.delete('APPOPTICS_SERVICE_KEY')

    AppOpticsAPM::Config[:hostname_alias] = 'string_0'
    AppOpticsAPM::Config[:debug_level] = 0
    AppOpticsAPM::Config[:service_key] = 'string_1'

    AppOpticsAPM::OboeInitOptions.instance.re_init
    options = AppOpticsAPM::OboeInitOptions.instance.array_for_oboe

    options.size.must_equal 17

    options[0].must_equal 'string_0'
    options[1].must_equal 0
    options[9].must_equal 'string_1'
  end

  it 'env vars override config vars' do
    ENV['APPOPTICS_HOSTNAME_ALIAS'] = 'string_0'
    ENV['APPOPTICS_DEBUG_LEVEL'] = '1'
    ENV['APPOPTICS_SERVICE_KEY'] = 'string_1'

    AppOpticsAPM::Config[:hostname_alias] = 'string_2'
    AppOpticsAPM::Config[:debug_level] = 2
    AppOpticsAPM::Config[:service_key] = 'string_3'

    AppOpticsAPM::OboeInitOptions.instance.re_init
    options = AppOpticsAPM::OboeInitOptions.instance.array_for_oboe

    options.size.must_equal 17

    options[0].must_equal 'string_0'
    options[1].must_equal 1
    options[9].must_equal 'string_1'
  end

  it 'checks the service_key for ssl' do
    ENV.delete('APPOPTICS_GEM_TEST')
    ENV['APPOPTICS_REPORTER'] = 'ssl'
    ENV['APPOPTICS_SERVICE_KEY'] = 'string_0'

    AppOpticsAPM::OboeInitOptions.instance.re_init
    AppOpticsAPM::OboeInitOptions.instance.service_key_ok?.must_equal false

    ENV['APPOPTICS_SERVICE_KEY'] = '2895f613c0f452d6bc5dc000008f6754062689e224ec245926be520be0c00000:test_app'

    AppOpticsAPM::OboeInitOptions.instance.re_init
    AppOpticsAPM::OboeInitOptions.instance.service_key_ok?.must_equal true
  end

  it 'returns true for the service_key check for other reporters' do
    ENV.delete('APPOPTICS_GEM_TEST')
    ENV['APPOPTICS_REPORTER'] = 'udp'
    ENV['APPOPTICS_SERVICE_KEY'] = 'string_0'

    AppOpticsAPM::OboeInitOptions.instance.re_init
    AppOpticsAPM::OboeInitOptions.instance.service_key_ok?.must_equal true

    ENV['APPOPTICS_REPORTER'] = 'file'

    AppOpticsAPM::OboeInitOptions.instance.re_init
    AppOpticsAPM::OboeInitOptions.instance.service_key_ok?.must_equal true

    ENV['APPOPTICS_REPORTER'] = 'null'

    AppOpticsAPM::OboeInitOptions.instance.re_init
    AppOpticsAPM::OboeInitOptions.instance.service_key_ok?.must_equal true
  end

  it 'validates the service key' do
    AppOpticsAPM.logger.level = 6
    ENV.delete('APPOPTICS_GEM_TEST')
    ENV['APPOPTICS_REPORTER'] = 'ssl'
    ENV['APPOPTICS_SERVICE_KEY'] = nil
    AppOpticsAPM::Config[:service_key] = nil

    AppOpticsAPM::OboeInitOptions.instance.re_init
    AppOpticsAPM::OboeInitOptions.instance.service_key_ok?.must_equal false

    AppOpticsAPM::Config[:service_key] = '22222222-2222-2222-2222-222222222222:service'
    AppOpticsAPM::OboeInitOptions.instance.re_init
    AppOpticsAPM::OboeInitOptions.instance.service_key_ok?.must_equal false

    AppOpticsAPM::Config[:service_key] = '1234567890123456789012345678901234567890123456789012345678901234'
    AppOpticsAPM::OboeInitOptions.instance.re_init
    AppOpticsAPM::OboeInitOptions.instance.service_key_ok?.must_equal false

    AppOpticsAPM::Config[:service_key] = '1234567890123456789012345678901234567890123456789012345678901234:'
    AppOpticsAPM::OboeInitOptions.instance.re_init
    AppOpticsAPM::OboeInitOptions.instance.service_key_ok?.must_equal false

    AppOpticsAPM::Config[:service_key] = '1234567890123456789012345678901234567890123456789012345678901234:service'
    AppOpticsAPM::OboeInitOptions.instance.re_init
    AppOpticsAPM::OboeInitOptions.instance.service_key_ok?.must_equal true

    ENV['APPOPTICS_SERVICE_KEY'] = 'blabla'
    AppOpticsAPM::OboeInitOptions.instance.re_init
    AppOpticsAPM::OboeInitOptions.instance.service_key_ok?.must_equal false

    ENV['APPOPTICS_SERVICE_KEY'] = nil
    AppOpticsAPM::OboeInitOptions.instance.re_init
    AppOpticsAPM::OboeInitOptions.instance.service_key_ok?.must_equal true

    ENV['APPOPTICS_SERVICE_KEY'] = '22222222-2222-2222-2222-222222222222:service'
    AppOpticsAPM::OboeInitOptions.instance.re_init
    AppOpticsAPM::OboeInitOptions.instance.service_key_ok?.must_equal false

    ENV['APPOPTICS_SERVICE_KEY'] = '1234567890123456789012345678901234567890123456789012345678901234'
    AppOpticsAPM::OboeInitOptions.instance.re_init
    AppOpticsAPM::OboeInitOptions.instance.service_key_ok?.must_equal false

    ENV['APPOPTICS_SERVICE_KEY'] = '1234567890123456789012345678901234567890123456789012345678901234:'
    AppOpticsAPM::OboeInitOptions.instance.re_init
    AppOpticsAPM::OboeInitOptions.instance.service_key_ok?.must_equal false

    ENV['APPOPTICS_SERVICE_KEY'] = '1234567890123456789012345678901234567890123456789012345678901234:service'
    AppOpticsAPM::OboeInitOptions.instance.re_init
    AppOpticsAPM::OboeInitOptions.instance.service_key_ok?.must_equal true
 end
end