Rails.application.routes.draw do
  root "walls#show"

  resources :posts, only: [ :index, :create ]
end
