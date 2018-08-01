Coverband.configure do |config|
  config.root              = Dir.pwd
  config.collector         = 'coverage'
  config.redis             = Redis.new() if defined? Redis
  # TODO NOTE THIS IS A ISSUE IN THE 2.0 release you set something like redis and the store
  # I need to look a bit more at this but got one bug report quickly after release
  # (even though test builds didnt need)
  config.store             = Redis.new() if defined? Redis
  config.ignore            = %w[vendor .erb$ .slim$]
  # add paths that you deploy to that might be different than your local dev root path
  config.root_paths        = []

  # reporting frequency
  # if you are debugging changes to coverband I recommend setting to 100.0
  # otherwise it is find to report slowly over time with less performance impact
  # with the Coverage collector coverage is ALWAYS captured this is just how frequently
  # it is reported to your back end store.
  config.percentage        = Rails.env.production? ? 1.0 : 100.0
  config.logger            = Rails.logger

  # config options false, true, or 'debug'. Always use false in production
  # true and debug can give helpful and interesting code usage information
  # they both increase the performance overhead of the gem a little.
  # they can also help with initially debugging the installation.
  # config.verbose           = 'debug'
end
