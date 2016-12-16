Rails.application.routes.draw do

  devise_for :users

  authenticated :user  do
    root to: 'cases#index', as: :authenticated_root
  end

  resources :cases do
    resources :assignments
  end

  get '/search' => 'cases#search'

  get 'ping', to: 'heartbeat#ping', format: :json

  root to: redirect('/users/sign_in')
end
