# frozen_string_literal: true

Rails.application.routes.draw do
  root 'walls#show'

  resource  :age_confirmation, only: %i[create destroy]
  resource  :proximity,        only: %i[create destroy], controller: 'proximity'
  resources :posts, only: %i[index create] do
    resource :report, only: :create
  end

  get '/terms',   to: 'pages#terms',   as: :terms
  get '/privacy', to: 'pages#privacy', as: :privacy

  namespace :admin do
    resources :posts, only: %i[index destroy]
  end
end
