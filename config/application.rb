require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CoverbandDemo
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2
    config.generators.javascript_engine = :js

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Coverband needs to be setup before any of the initializers to capture usage of them
    require 'coverband'
    Coverband.configure
    config.middleware.use Coverband::Middleware

    # if one uses before_eager_load as I did previously
    # any files that get loaded as part of railties will have no coverage
    config.before_initialize do
      require 'coverage'
      Coverband::Collectors::Base.instance.start
    end


  end
end
