# frozen_string_literal: true

# 4.x configuration
Coverband.configure do |config|
  # toggle allowing folks to clear coverband from web-ui
  config.web_enable_clear = true

  # toggle on and off web debug
  # allowing one to dump full coverband stored json data to web
  config.web_debug = true

  # toggle on and off tracking gems
  config.track_gems = true

  # toggle on and off gem file details
  config.gem_details = true

  # better ignores
  config.ignore += %w[config/application.rb
                      config/boot.rb
                      config/puma.rb
                      config/environments/test.rb
                      config/environments/development.rb
                      config/environments/production.rb]

  # configure S3 integration
  # config.s3_bucket = 'coverband-demo'
  # config.s3_region = 'us-east-1'
  # config.s3_access_key_id = ENV['AWS_ACCESS_KEY_ID']
  # config.s3_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']

  # This tests a stand alone rubyscript collecting its own Coverage
  # The script loads coverband and therefor needs to be reloaded
  config.safe_reload_files = ['bin/script_test.rb']

  # config options false, true, or 'debug'. Always use false in production
  # true and debug can give helpful and interesting code usage information
  # they both increase the performance overhead of the gem a little.
  # they can also help with initially debugging the installation.
  # config.verbose = 'debug'
end
