require 'coverband/s3_web'

# protect with existing Rails devise configuration
devise_constraint = lambda do |request|
  request.env['warden'] && request.env['warden'].authenticate? && request.env['warden'].user.admin?
end

# protect with http basic auth
# curl --user foo:bar http://localhost:3000/coverage
basic_constraint = lambda do |request|
  return true if Rails.env.development?
  if ActionController::HttpAuthentication::Basic.has_basic_credentials?(request)
    credentials = ActionController::HttpAuthentication::Basic.decode_credentials(request)
    email, password = credentials.split(':')

    email == 'foo' && password = 'bar'
  end
end

Rails.application.routes.draw do
  root 'home#index'
  resources :posts

  constraints basic_constraint do
    mount Coverband::S3Web, at: '/coverage'
  end
end
