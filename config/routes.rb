Rails.application.routes.draw do

  devise_for :users

  authenticated :user  do
    root to: 'correspondence#index', as: :authenticated_root
  end

  resources :correspondence do
    member do
      patch 'assign'
    end
  end

  namespace :api, format: :json do
    scope module: :v1 do
      resources :correspondence, format: :json, only: :create
    end
  end

  get '/search' => 'correspondence#search'

  root to: redirect('/users/sign_in')
end
