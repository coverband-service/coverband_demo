require 'coverband/s3_web'

Rails.application.routes.draw do
  root 'home#index'
  resources :posts
  mount Coverband::S3Web, at: '/coverage'
  #match "/coverage" => Coverband::S3Web, via: [:get]
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
