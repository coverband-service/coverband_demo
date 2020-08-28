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

    email == 'foo' && password == 'bar'
  end
end

class AdminConstraint
  def matches?(request)
    request.session["init"] = true
    Rails.logger.info "admin request session: #{request.session.inspect}"
    return false if request.session[:admin_id].blank?
    return true if User.find_by(id: request.session[:admin_id])&.admin?

    false
  end
end

Rails.application.routes.draw do
  root 'home#index'
  get '/trigger_jobs' => 'home#trigger_jobs'
  get '/data_tracer' => 'home#data_tracer'
  resources :posts do
    collection do
      post 'destroy_bad_posts'
      post 'destroy_bad_dangerously'
    end
  end

  # NOTE make sure to have a constrait around any real production app
  # the demo app below purposefully shares it source code, but you likely do not want to
  # constraints basic_constraint do
  #  mount Coverband::S3Web, at: '/coverage'
  # end
  mount Coverband::Reporters::Web.new, at: '/coverage'

  # example of basic containts
  # curl --user foo:bar http://localhost:3000/basic/restricted_coverage
  scope :basic, constraints: basic_constraint do
    mount Coverband::Reporters::Web.new, at: '/restricted_coverage'
  end

  # example of more complex restraint
  scope :admin, constraints: AdminConstraint.new do
    mount Coverband::Reporters::Web.new, at: '/restricted_coverage'
  end
end
