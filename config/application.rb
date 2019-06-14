require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.

# require coverband here to ensure tracking of all gems
# require 'coverband'

Bundler.require(*Rails.groups)
require 'sidekiq/api'

# require coverband here with a gemfile of require: false
# to ensure that no gem data is tracked which has slight performance and memory hits
require 'coverband'

module CoverbandDemo
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2
    config.generators.javascript_engine = :js
    # ensure we get the fonts
    config.assets.precompile << /\.(?:svg|eot|woff|woff2|ttf)$/

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
