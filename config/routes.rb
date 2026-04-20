# frozen_string_literal: true

Rails.application.routes.draw do
  root 'walls#show'

  resource  :proximity, only: %i[create destroy], controller: 'proximity'
  resources :posts,     only: %i[index create]
end
