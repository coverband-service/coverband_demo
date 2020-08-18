Coverband.configure do |config|
  # add local ignores, ignores listed here will filter and never send data to Coverband service
  config.ignore = %w[config/application.rb
                     config/boot.rb
                     config/coverband.rb]

  # set API key via Rails configs opposed to ENV vars
  # config.api_key = Rails.application.credentials.coverband_api_key

  # when debugging it is nice to report often
  config.background_reporting_sleep_seconds = 10

  # Logging when debugging
  config.logger = Rails.logger
  # enable to debug in development if having issues sending files
  # config.verbose = true
end
