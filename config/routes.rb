Rails.application.routes.draw do

  devise_for :users

  authenticated :user  do
    root to: 'correspondence#index', as: :authenticated_root
  end

  resources :correspondence do
    member do
      patch 'assign'
      get 'acceptance'
    end
  end

  get '/search' => 'correspondence#search'

  root to: redirect('/users/sign_in')
end
