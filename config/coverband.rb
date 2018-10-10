# frozen_string_literal: true

Coverband.configure do |config|
  config.root              = Dir.pwd
  config.collector         = 'coverage'
  # TODO: document how to use memory_caching in coverband Readme
  config.memory_caching    = true
  config.store = if ENV['REDIS_URL']
                   Coverband::Adapters::RedisStore.new(Redis.new(url: ENV['REDIS_URL']))
                 else
                   Coverband::Adapters::RedisStore.new(Redis.new)
                 end

  config.ignore            = %w[vendor .erb$ .slim$]
  # add paths that deploy to that might be different than local dev root path
  config.root_paths        = []

  # reporting frequency
  # if you are debugging changes to coverband I recommend setting to 100.0
  # otherwise it is find to report slowly over time with less performance impact
  # with Coverage collector coverage is ALWAYS captured this is how frequently
  # it is reported to your back end store.
  # NOTE: the demo site sends data for EVERY request so one can see the effects
  # do not send 100.0 in production!
  config.percentage        = Rails.env.production? ? 100.0 : 100.0
  config.logger            = Rails.logger

  # configure S3 integration
  config.s3_bucket = 'coverband-demo'
  config.s3_region = 'us-east-1'
  config.s3_access_key_id = ENV['AWS_ACCESS_KEY_ID']
  config.s3_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']

  # using the new safe reload to enforce files loaded
  config.safe_reload_files = ['config/coverband.rb']

  # config options false, true, or 'debug'. Always use false in production
  # true and debug can give helpful and interesting code usage information
  # they both increase the performance overhead of the gem a little.
  # they can also help with initially debugging the installation.
  # config.verbose           = 'debug'
end
