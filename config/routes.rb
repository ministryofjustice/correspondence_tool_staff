Rails.application.routes.draw do

  resources :correspondence

  namespace :api, format: :json do
    scope module: :v1 do
      resources :correspondence, format: :json, only: :create
    end
  end

  root to: 'correspondence#index'

  get '/search' => 'correspondence#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
