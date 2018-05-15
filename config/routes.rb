# == Route Map
#
#                                     Prefix Verb   URI Pattern                                                          Controller#Action
#                           new_user_session GET    /users/sign_in(.:format)                                             devise/sessions#new
#                               user_session POST   /users/sign_in(.:format)                                             devise/sessions#create
#                       destroy_user_session DELETE /users/sign_out(.:format)                                            devise/sessions#destroy
#                          new_user_password GET    /users/password/new(.:format)                                        passwords#new
#                         edit_user_password GET    /users/password/edit(.:format)                                       passwords#edit
#                              user_password PATCH  /users/password(.:format)                                            passwords#update
#                                            PUT    /users/password(.:format)                                            passwords#update
#                                            POST   /users/password(.:format)                                            passwords#create
#                            new_user_unlock GET    /users/unlock/new(.:format)                                          devise/unlocks#new
#                                user_unlock GET    /users/unlock(.:format)                                              devise/unlocks#show
#                                            POST   /users/unlock(.:format)                                              devise/unlocks#create
#                               manager_root GET    /                                                                    redirect(301, /cases/open/in_time)
#                             responder_root GET    /                                                                    redirect(301, /cases/open/in_time)
#                              approver_root GET    /                                                                    redirect(301, /cases/open/in_time)
#                                sidekiq_web        /sidekiq                                                             Sidekiq::Web
#                                   feedback POST   /feedback(.:format)                                                  feedback#create
#                         cases_manager_root GET    /cases(.:format)                                                     redirect(301, /cases/open/in_time)
#                       cases_responder_root GET    /cases(.:format)                                                     redirect(301, /cases/open/in_time)
#                        cases_approver_root GET    /cases(.:format)                                                     redirect(301, /cases/open/in_time)
#                                            GET    /cases/new(.:format)                                                 cases#new
#                                   new_case GET    /cases/new/:correspondence_type(.:format)                            cases#new {:correspondence_type=>""}
#                                 close_case GET    /cases/:id/close(.:format)                                           cases#close
#                               closed_cases GET    /cases/closed(.:format)                                              cases#closed_cases
#                       confirm_destroy_case GET    /cases/:id/confirm_destroy(.:format)                                 cases#confirm_destroy
#                             incoming_cases GET    /cases/incoming(.:format)                                            cases#incoming_cases
#                         root_my_open_cases GET    /cases/my_open(.:format)                                             redirect(301, /cases/my_open/in_time)
#                              my_open_cases GET    /cases/my_open/:tab(.:format)                                        cases#my_open_cases
#                            root_open_cases GET    /cases/open(.:format)                                                redirect(301, /cases/open/in_time)
#                                 open_cases GET    /cases/open/:tab(.:format)                                           cases#open_cases
#                       process_closure_case PATCH  /cases/:id/process_closure(.:format)                                 cases#process_closure
#                               respond_case GET    /cases/:id/respond(.:format)                                         cases#respond
#                       confirm_respond_case PATCH  /cases/:id/confirm_respond(.:format)                                 cases#confirm_respond
#             case_assignments_show_rejected GET    /cases/:case_id/assignments/show_rejected(.:format)                  assignments#show_rejected
#              case_assign_to_responder_team GET    /cases/:case_id/assignments/assign_to_team(.:format)                 assignments#assign_to_team
#                  unflag_for_clearance_case PATCH  /cases/:id/unflag_for_clearance(.:format)                            cases#unflag_for_clearance
#    unflag_taken_on_case_for_clearance_case PATCH  /cases/:id/unflag_taken_on_case_for_clearance(.:format)              cases#unflag_taken_on_case_for_clearance
#                    flag_for_clearance_case PATCH  /cases/:id/flag_for_clearance(.:format)                              cases#flag_for_clearance
#                      approve_response_case GET    /cases/:id/approve_response(.:format)                                cases#approve_response
#         approve_response_interstitial_case GET    /cases/:id/approve_response_interstitial(.:format)                   cases#approve_response_interstitial
#             execute_response_approval_case POST   /cases/:id/execute_response_approval(.:format)                       cases#execute_response_approval
#                        request_amends_case GET    /cases/:id/request_amends(.:format)                                  cases#request_amends
#                execute_request_amends_case PATCH  /cases/:id/execute_request_amends(.:format)                          cases#execute_request_amends
#                               filter_cases POST   /cases/filter(.:format)                                              cases#filter
#                      remove_clearance_case GET    /cases/:id/remove_clearance(.:format)                                cases#remove_clearance
#                        extend_for_pit_case GET    /cases/:id/extend_for_pit(.:format)                                  cases#extend_for_pit
#                execute_extend_for_pit_case PATCH  /cases/:id/execute_extend_for_pit(.:format)                          cases#execute_extend_for_pit
#             request_further_clearance_case PATCH  /cases/:id/request_further_clearance(.:format)                       cases#request_further_clearance
#                         new_case_link_case GET    /cases/:id/new_case_link(.:format)                                   cases#new_case_link
#                 execute_new_case_link_case POST   /cases/:id/execute_new_case_link(.:format)                           cases#execute_new_case_link
#                       destroy_link_on_case DELETE /cases/:id/destroy_link/:linked_case_number(.:format)                cases#destroy_case_link
#           accept_or_reject_case_assignment PATCH  /cases/:case_id/assignments/:id/accept_or_reject(.:format)           assignments#accept_or_reject
#                     accept_case_assignment PATCH  /cases/:case_id/assignments/:id/accept(.:format)                     assignments#accept
#                   unaccept_case_assignment PATCH  /cases/:case_id/assignments/:id/unaccept(.:format)                   assignments#unaccept
#               take_case_on_case_assignment PATCH  /cases/:case_id/assignments/:id/take_case_on(.:format)               assignments#take_case_on
#              reassign_user_case_assignment GET    /cases/:case_id/assignments/:id/reassign_user(.:format)              assignments#reassign_user
#         assign_to_new_team_case_assignment GET    /cases/:case_id/assignments/:id/assign_to_new_team(.:format)         assignments#assign_to_new_team
#               select_team_case_assignments GET    /cases/:case_id/assignments/select_team(.:format)                    assignments#select_team
#      execute_reassign_user_case_assignment PATCH  /cases/:case_id/assignments/:id/execute_reassign_user(.:format)      assignments#execute_reassign_user
# execute_assign_to_new_team_case_assignment PATCH  /cases/:case_id/assignments/:id/execute_assign_to_new_team(.:format) assignments#execute_assign_to_new_team
#                           case_assignments GET    /cases/:case_id/assignments(.:format)                                assignments#index
#                        new_case_assignment GET    /cases/:case_id/assignments/new(.:format)                            assignments#new
#                       edit_case_assignment GET    /cases/:case_id/assignments/:id/edit(.:format)                       assignments#edit
#                            case_assignment GET    /cases/:case_id/assignments/:id(.:format)                            assignments#show
#                                            PATCH  /cases/:case_id/assignments/:id(.:format)                            assignments#update
#                                            PUT    /cases/:case_id/assignments/:id(.:format)                            assignments#update
#                                            DELETE /cases/:case_id/assignments/:id(.:format)                            assignments#destroy
#                      case_case_attachments GET    /cases/:case_id/attachments(.:format)                                case_attachments#index
#                                            POST   /cases/:case_id/attachments(.:format)                                case_attachments#create
#                   new_case_case_attachment GET    /cases/:case_id/attachments/new(.:format)                            case_attachments#new
#                  edit_case_case_attachment GET    /cases/:case_id/attachments/:id/edit(.:format)                       case_attachments#edit
#                       case_case_attachment GET    /cases/:case_id/attachments/:id(.:format)                            case_attachments#show
#                                            PATCH  /cases/:case_id/attachments/:id(.:format)                            case_attachments#update
#                                            PUT    /cases/:case_id/attachments/:id(.:format)                            case_attachments#update
#                                            DELETE /cases/:case_id/attachments/:id(.:format)                            case_attachments#destroy
#                              case_messages POST   /cases/:case_id/messages(.:format)                                   messages#create
#                   new_response_upload_case GET    /cases/:id/new_response_upload(.:format)                             cases#new_response_upload
#                      upload_responses_case POST   /cases/:id/upload_responses(.:format)                                cases#upload_responses
#              download_case_case_attachment GET    /cases/:case_id/attachments/:id/download(.:format)                   case_attachments#download
#                                            DELETE /cases/:case_id/attachments/:id(.:format)                            case_attachments#destroy
#                               search_cases GET    /cases/search(.:format)                                              cases#search
#                                      cases GET    /cases(.:format)                                                     cases#index
#                                            POST   /cases(.:format)                                                     cases#create
#                                  edit_case GET    /cases/:id/edit(.:format)                                            cases#edit
#                                       case GET    /cases/:id(.:format)                                                 cases#show
#                                            PATCH  /cases/:id(.:format)                                                 cases#update
#                                            PUT    /cases/:id(.:format)                                                 cases#update
#                                            DELETE /cases/:id(.:format)                                                 cases#destroy
#                                 admin_root GET    /admin(.:format)                                                     admin#index
#                                admin_cases GET    /admin/cases(.:format)                                               admin/cases#index
#                                            POST   /admin/cases(.:format)                                               admin/cases#create
#                             new_admin_case GET    /admin/cases/new(.:format)                                           admin/cases#new
#                            edit_admin_case GET    /admin/cases/:id/edit(.:format)                                      admin/cases#edit
#                                 admin_case GET    /admin/cases/:id(.:format)                                           admin/cases#show
#                                            PATCH  /admin/cases/:id(.:format)                                           admin/cases#update
#                                            PUT    /admin/cases/:id(.:format)                                           admin/cases#update
#                                            DELETE /admin/cases/:id(.:format)                                           admin/cases#destroy
#                                 team_users GET    /teams/:team_id/users(.:format)                                      users#index
#                                            POST   /teams/:team_id/users(.:format)                                      users#create
#                              new_team_user GET    /teams/:team_id/users/new(.:format)                                  users#new
#                             edit_team_user GET    /teams/:team_id/users/:id/edit(.:format)                             users#edit
#                                  team_user GET    /teams/:team_id/users/:id(.:format)                                  users#show
#                                            PATCH  /teams/:team_id/users/:id(.:format)                                  users#update
#                                            PUT    /teams/:team_id/users/:id(.:format)                                  users#update
#                                            DELETE /teams/:team_id/users/:id(.:format)                                  users#destroy
#                      areas_covered_by_team GET    /teams/:id/business_areas_covered(.:format)                          teams#business_areas_covered
#               create_areas_covered_by_team POST   /teams/:id/create_areas_covered(.:format)                            teams#create_business_areas_covered
#                 destroy_business_area_team DELETE /teams/:id/destroy_business_area(.:format)                           teams#destroy_business_area
#                  update_business_area_team PATCH  /teams/:id/update_business_area(.:format)                            teams#update_business_area
#             update_business_area_form_team GET    /teams/:id/update_business_area_form(.:format)                       teams#update_business_area_form
#                                      teams GET    /teams(.:format)                                                     teams#index
#                                            POST   /teams(.:format)                                                     teams#create
#                                   new_team GET    /teams/new(.:format)                                                 teams#new
#                                  edit_team GET    /teams/:id/edit(.:format)                                            teams#edit
#                                       team GET    /teams/:id(.:format)                                                 teams#show
#                                            PATCH  /teams/:id(.:format)                                                 teams#update
#                                            PUT    /teams/:id(.:format)                                                 teams#update
#                                            DELETE /teams/:id(.:format)                                                 teams#destroy
#                                 user_teams GET    /users/:user_id/teams(.:format)                                      teams#index
#                                      users GET    /users(.:format)                                                     users#index
#                                            POST   /users(.:format)                                                     users#create
#                                   new_user GET    /users/new(.:format)                                                 users#new
#                                  edit_user GET    /users/:id/edit(.:format)                                            users#edit
#                                       user GET    /users/:id(.:format)                                                 users#show
#                                            PATCH  /users/:id(.:format)                                                 users#update
#                                            PUT    /users/:id(.:format)                                                 users#update
#                                            DELETE /users/:id(.:format)                                                 users#destroy
#                                      stats GET    /stats(.:format)                                                     stats#index
#                             stats_download GET    /stats/download/:id(.:format)                                        stats#download
#               stats_download_custom_report GET    /stats/download_custom_report/:id(.:format)                          stats#download_custom_report
#                               stats_custom GET    /stats/custom(.:format)                                              stats#custom
#                 stats_create_custom_report POST   /stats/create_custom_report(.:format)                                stats#create_custom_report
#                                     search GET    /search(.:format)                                                    cases#search
#                                       ping GET    /ping(.:format)                                                      heartbeat#ping
#                                healthcheck GET    /healthcheck(.:format)                                               heartbeat#healthcheck
#                            dashboard_cases GET    /dashboard/cases(.:format)                                           dashboard#cases
#                         dashboard_feedback GET    /dashboard/feedback(.:format)                                        dashboard#feedback
#                        dashboard_exception GET    /dashboard/exception(.:format)                                       dashboard#exception
#                   dashboard_search_queries GET    /dashboard/search_queries(.:format)                                  dashboard#search_queries
#                                       root GET    /                                                                    redirect(301, /users/sign_in)
#

# For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

require 'sidekiq/web'

Rails.application.routes.draw do

  # devise_for :users
  devise_for :users, controllers: { passwords: 'passwords' }

  gnav = Settings.global_navigation

  authenticated :user, -> (u) { u.manager? }  do
    root to: redirect(gnav.default_urls.manager), as: :manager_root
  end

  authenticated :user, -> (u) { u.responder?}  do
    root to: redirect(gnav.default_urls.responder), as: :responder_root
  end

  authenticated :user, -> (u) { u.approver?}  do
    root to: redirect(gnav.default_urls.approver), as: :approver_root
  end


  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  post '/feedback' => 'feedback#create'

  resources :cases, except: :new do
    authenticated :user, -> (u) { u.manager? }  do
      root to: redirect(gnav.default_urls.manager), as: :manager_root
    end

    authenticated :user, -> (u) { u.responder?}  do
      root to: redirect(gnav.default_urls.responder), as: :responder_root
    end

    authenticated :user, -> (u) { u.approver?}  do
      root to: redirect(gnav.default_urls.approver), as: :approver_root
    end

    # Oh case, we barely new you.
    #
    # The following two routes are necessary to proved the paths:
    # /cases/new                      - select the type of correspondence for the new case
    # /cases/new/foi, /cases/new/sar  - create a new case for the given correspondence type
    get '', action: :new, on: :new
    get ':correspondence_type',
        action: :new,
        on: :new,
        as: '',
        defaults: { correspondence_type: '' }
    get 'close', on: :member
    get 'closed' => 'cases#closed_cases', on: :collection
    get 'confirm_destroy' => 'cases#confirm_destroy', on: :member
    get 'incoming' => 'cases#incoming_cases', on: :collection
    get 'my_open', on: :collection, to: redirect('/cases/my_open/in_time'), as: :root_my_open
    get 'my_open/:tab' => 'cases#my_open_cases', on: :collection, as: :my_open
    get 'open', on: :collection, to: redirect('/cases/open/in_time'), as: :root_open
    get 'open/:tab' => 'cases#open_cases', on: :collection, as: :open
    patch 'process_closure', on: :member
    get 'respond', on: :member
    patch 'confirm_respond', on: :member
    get '/assignments/show_rejected' => 'assignments#show_rejected'
    get '/assignments/assign_to_team' => 'assignments#assign_to_team', as: 'assign_to_responder_team'
    patch 'unflag_for_clearance' => 'cases#unflag_for_clearance', on: :member
    patch 'unflag_taken_on_case_for_clearance' => 'cases#unflag_taken_on_case_for_clearance', on: :member
    patch 'flag_for_clearance' => 'cases#flag_for_clearance', on: :member
    get 'approve_response' => 'cases#approve_response', on: :member
    get 'approve_response_interstitial' => 'cases#approve_response_interstitial', on: :member
    post 'execute_response_approval' => 'cases#execute_response_approval', on: :member
    get :request_amends, on: :member
    patch :execute_request_amends, on: :member
    post  :filter, on: :collection
    get 'remove_clearance' => 'cases#remove_clearance', on: :member
    # get 'upload_response_approve' => 'cases#upload_response_approve', on: :member
    get :extend_for_pit, on: :member
    patch :execute_extend_for_pit, on: :member
    patch :request_further_clearance, on: :member
    get :new_case_link, on: :member
    post :execute_new_case_link, on: :member
    delete 'destroy_link/:linked_case_number' => 'cases#destroy_case_link' , on: :member, as: 'destroy_link_on'

    resources :assignments, except: :create  do
      patch 'accept_or_reject', on: :member
      patch 'accept', on: :member
      patch 'unaccept', on: :member
      patch 'take_case_on', on: :member
      get :reassign_user , on: :member
      get :assign_to_new_team, on: :member
      get :select_team, on: :collection
      patch :execute_reassign_user, on: :member
      patch :execute_assign_to_new_team, on: :member
    end

    resources :case_attachments, path: 'attachments'

    resources :messages, only: :create

    get 'new_response_upload', on: :member
    post 'upload_responses', on: :member

    resources :case_attachments, path: 'attachments', only: [:destroy] do
      get 'download', on: :member
    end

    get 'search' => 'cases#search', on: :collection
  end

  namespace :admin do
    root to: 'admin/cases', action: :index
    resources :cases
  end

  resources :teams do
    resources :users

    get 'business_areas_covered' => 'teams#business_areas_covered',
        as: 'areas_covered_by', on: :member
    post 'create_areas_covered'=> 'teams#create_business_areas_covered',
        as: 'create_areas_covered_by', on: :member
    delete 'destroy_business_area' => 'teams#destroy_business_area', on: :member
    patch 'update_business_area' => 'teams#update_business_area', on: :member
    get 'update_business_area_form' => 'teams#update_business_area_form', on: :member

  end

  authenticate :user do
    resources :users do
      resources :teams, only: :index
    end
  end

  get '/stats' => 'stats#index'
  get '/stats/download/:id' => 'stats#download', as: :stats_download
  get '/stats/download_custom_report/:id' => 'stats#download_custom_report', as: :stats_download_custom_report
  get '/stats/custom' => 'stats#custom'
  post 'stats/create_custom_report' => 'stats#create_custom_report'

  get '/search' => 'cases#search'

  get 'ping', to: 'heartbeat#ping', format: :json

  get 'healthcheck',    to: 'heartbeat#healthcheck',  as: 'healthcheck', format: :json


  get '/dashboard/cases' => 'dashboard#cases'
  get '/dashboard/feedback' => 'dashboard#feedback'
  get '/dashboard/exception' => 'dashboard#exception'
  get '/dashboard/search_queries' => 'dashboard#search_queries'
  get '/dashboard/list_queries' => 'dashboard#list_queries'

  root to: redirect('/users/sign_in')
end
