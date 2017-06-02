# == Route Map
#
#                           Prefix Verb   URI Pattern                                                Controller#Action
#                 new_user_session GET    /users/sign_in(.:format)                                   devise/sessions#new
#                     user_session POST   /users/sign_in(.:format)                                   devise/sessions#create
#             destroy_user_session DELETE /users/sign_out(.:format)                                  devise/sessions#destroy
#               authenticated_root GET    /                                                          cases#index
#                      sidekiq_web        /sidekiq                                                   Sidekiq::Web
#                         feedback POST   /feedback(.:format)                                        feedback#create
#                       close_case GET    /cases/:id/close(.:format)                                 cases#close
#             process_closure_case PATCH  /cases/:id/process_closure(.:format)                       cases#process_closure
#                     respond_case GET    /cases/:id/respond(.:format)                               cases#respond
#             confirm_respond_case PATCH  /cases/:id/confirm_respond(.:format)                       cases#confirm_respond
#   case_assignments_show_rejected GET    /cases/:case_id/assignments/show_rejected(.:format)        assignments#show_rejected
# accept_or_reject_case_assignment PATCH  /cases/:case_id/assignments/:id/accept_or_reject(.:format) assignments#accept_or_reject
#                 case_assignments GET    /cases/:case_id/assignments(.:format)                      assignments#index
#                                  POST   /cases/:case_id/assignments(.:format)                      assignments#create
#              new_case_assignment GET    /cases/:case_id/assignments/new(.:format)                  assignments#new
#             edit_case_assignment GET    /cases/:case_id/assignments/:id/edit(.:format)             assignments#edit
#                  case_assignment GET    /cases/:case_id/assignments/:id(.:format)                  assignments#show
#                                  PATCH  /cases/:case_id/assignments/:id(.:format)                  assignments#update
#                                  PUT    /cases/:case_id/assignments/:id(.:format)                  assignments#update
#                                  DELETE /cases/:case_id/assignments/:id(.:format)                  assignments#destroy
#            case_case_attachments GET    /cases/:case_id/attachments(.:format)                      case_attachments#index
#                                  POST   /cases/:case_id/attachments(.:format)                      case_attachments#create
#         new_case_case_attachment GET    /cases/:case_id/attachments/new(.:format)                  case_attachments#new
#        edit_case_case_attachment GET    /cases/:case_id/attachments/:id/edit(.:format)             case_attachments#edit
#             case_case_attachment GET    /cases/:case_id/attachments/:id(.:format)                  case_attachments#show
#                                  PATCH  /cases/:case_id/attachments/:id(.:format)                  case_attachments#update
#                                  PUT    /cases/:case_id/attachments/:id(.:format)                  case_attachments#update
#                                  DELETE /cases/:case_id/attachments/:id(.:format)                  case_attachments#destroy
#         new_response_upload_case GET    /cases/:id/new_response_upload(.:format)                   cases#new_response_upload
#            upload_responses_case POST   /cases/:id/upload_responses(.:format)                      cases#upload_responses
#    download_case_case_attachment GET    /cases/:case_id/attachments/:id/download(.:format)         case_attachments#download
#                                  DELETE /cases/:case_id/attachments/:id(.:format)                  case_attachments#destroy
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

require 'sidekiq/web'

Rails.application.routes.draw do

  devise_for :users

  authenticated :user  do
    root to: redirect('/cases/open'), as: :authenticated_root
  end

  # TODO: Limit this to the admin users, as soon as we figure out how we
  #       recognize them. Here's a sample of how to do this using Devise:
  #
  # authenticate :user, lambda { |u| u.admin? } do
  authenticate :user do
    mount Sidekiq::Web => '/sidekiq'
  end

  post '/feedback' => 'feedback#create'

  resources :cases do
    get '/', to: redirect('/cases/open'), on: :collection
    get 'close', on: :member
    get 'closed' => 'cases#closed_cases', on: :collection
    get 'incoming' => 'cases#incoming_cases', on: :collection
    get 'my_open' => 'cases#my_open_cases', on: :collection
    get 'open' => 'cases#open_cases', on: :collection
    patch 'process_closure', on: :member
    get 'respond', on: :member
    patch 'confirm_respond', on: :member
    get '/assignments/show_rejected' => 'assignments#show_rejected'
    patch 'unflag_for_clearance' => 'cases#unflag_for_clearance', on: :member
    patch 'flag_for_clearance' => 'cases#flag_for_clearance', on: :member
    get 'approve_response' => 'cases#approve_response', on: :member
    patch 'execute_response_approval' => 'cases#execute_response_approval', on: :member
    patch 'reassign_approver' => 'cases#reassign_approver', on: :member

    resources :assignments do
      patch 'accept_or_reject', on: :member
      patch 'accept', on: :member
      patch 'unaccept', on: :member
    end

    resources :case_attachments, path: 'attachments'

    get 'new_response_upload', on: :member
    post 'upload_responses', on: :member

    resources :case_attachments, path: 'attachments', only: [:destroy] do
      get 'download', on: :member
    end
  end


  get '/search' => 'cases#search'

  get 'ping', to: 'heartbeat#ping', format: :json

  get 'healthcheck',    to: 'heartbeat#healthcheck',  as: 'healthcheck', format: :json

  root to: redirect('/users/sign_in')
end
