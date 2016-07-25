Rails.application.routes.draw do

  resources :correspondence

  root to: 'correspondence#index'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
