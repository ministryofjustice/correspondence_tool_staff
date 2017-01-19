# == Route Map
#
#                           Prefix Verb   URI Pattern                                                Controller#Action
#                 new_user_session GET    /users/sign_in(.:format)                                   devise/sessions#new
#                     user_session POST   /users/sign_in(.:format)                                   devise/sessions#create
#             destroy_user_session DELETE /users/sign_out(.:format)                                  devise/sessions#destroy
#                    user_password POST   /users/password(.:format)                                  devise/passwords#create
#                new_user_password GET    /users/password/new(.:format)                              devise/passwords#new
#               edit_user_password GET    /users/password/edit(.:format)                             devise/passwords#edit
#                                  PATCH  /users/password(.:format)                                  devise/passwords#update
#                                  PUT    /users/password(.:format)                                  devise/passwords#update
#               authenticated_root GET    /                                                          cases#index
# accept_or_reject_case_assignment PATCH  /cases/:case_id/assignments/:id/accept_or_reject(.:format) assignments#accept_or_reject
#                 case_assignments GET    /cases/:case_id/assignments(.:format)                      assignments#index
#                                  POST   /cases/:case_id/assignments(.:format)                      assignments#create
#              new_case_assignment GET    /cases/:case_id/assignments/new(.:format)                  assignments#new
#             edit_case_assignment GET    /cases/:case_id/assignments/:id/edit(.:format)             assignments#edit
#                  case_assignment GET    /cases/:case_id/assignments/:id(.:format)                  assignments#show
#                                  PATCH  /cases/:case_id/assignments/:id(.:format)                  assignments#update
#                                  PUT    /cases/:case_id/assignments/:id(.:format)                  assignments#update
#                                  DELETE /cases/:case_id/assignments/:id(.:format)                  assignments#destroy
#                            cases GET    /cases(.:format)                                           cases#index
#                                  POST   /cases(.:format)                                           cases#create
#                         new_case GET    /cases/new(.:format)                                       cases#new
#                        edit_case GET    /cases/:id/edit(.:format)                                  cases#edit
#                             case GET    /cases/:id(.:format)                                       cases#show
#                                  PATCH  /cases/:id(.:format)                                       cases#update
#                                  PUT    /cases/:id(.:format)                                       cases#update
#                                  DELETE /cases/:id(.:format)                                       cases#destroy
#                           search GET    /search(.:format)                                          cases#search
#                             ping GET    /ping(.:format)                                            heartbeat#ping
#                      healthcheck GET    /healthcheck(.:format)                                     heartbeat#healthcheck
#                             root GET    /                                                          redirect(301, /users/sign_in)
#

Rails.application.routes.draw do

  devise_for :users

  authenticated :user  do
    root to: 'cases#index', as: :authenticated_root
  end

  resources :cases do
    resources :assignments do
      patch 'accept_or_reject', on: :member
    end
  end

  get '/search' => 'cases#search'

  get 'ping', to: 'heartbeat#ping', format: :json

  get 'healthcheck',    to: 'heartbeat#healthcheck',  as: 'healthcheck', format: :json

  root to: redirect('/users/sign_in')
end
