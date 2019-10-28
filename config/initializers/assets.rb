# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')

###
# To keep a clean set of assets we fail fast when running rake assets:precompile
# We raise an exception if our CSS references a missing asset, during build time.
#
# This means we can safely delete images!
# If a page or CSS references an image that doesn't exist dev mode, build, or tests fail...
# until you add back the missing image or remove the old reference.
#
# Fails when:
#   * a page is loaded in dev mode referencing a missing asset
#   * tests are run against a page referencing a missing asset (ActionDispatch::IntegrationTest, request spec, etc)
#   * bundle exec rake assets:precompile
#
# The below config option Sprockets to raise instead of falling back to asset path without digest
# asset path without digest in other app setup means fall back to public or Rails served assets
# we do not support Rails assets in production, as most don't (public_file_server.enabled = false),
# falling back is dangerous (results in 404 images).

Rails.application.config.assets.unknown_asset_fallback = false

# NOTE: We monkey patch because the unknown_asset_fallback option
# doesn't seem to do what we expect, when compile scss see more below
#
# Rails.application.config.assets.unknown_asset_fallback = false
# ^^ The above works for image_tag("head_liner.svg") references, but fails for scss
#
# This patch ensures we also fail on scss
# patched against: sprockets (3.7.2), sprockets-rails (3.2.1), sass-rails (5.1.0)
# I suspect it is slightly different and perhaps the config works as expected in differnt versions
# of sprockets, sprockets-rails, sass-rails
#
# patching:
# https://github.com/rails/sprockets-rails/blob/49bf8022c8d3e1d7348b3fe2e0931b2e448f1f58/lib/sprockets/rails/context.rb#L21
###
module Sprockets
  module Rails
    module Context
      def compute_asset_path(path, options = {})
        @dependencies << 'actioncontroller-asset-url-config'

        begin
          asset_uri = resolve(path)
        rescue FileNotFound
          # TODO: eh, we should be able to use a form of locate that returns
          # nil instead of raising an exception.
          raise	Sprockets::Rails::Helper::AssetNotFound.new("path not resolved: #{path}")
      	end

      	if asset_uri
          asset = link_asset(path)
          digest_path = asset.digest_path
          path = digest_path if digest_assets
          File.join(assets_prefix || "/", path)
      	else
          super
      	end
      end
    end
  end
end
