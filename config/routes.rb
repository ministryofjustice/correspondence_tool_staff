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
#                               manager_root GET    /                                                                    redirect(301, /cases/open)
#                             responder_root GET    /                                                                    redirect(301, /cases/open)
#                              approver_root GET    /                                                                    redirect(301, /cases/open)
#                                sidekiq_web        /sidekiq                                                             Sidekiq::Web
#                                   feedback POST   /feedback(.:format)                                                  feedback#create
#                         cases_manager_root GET    /cases(.:format)                                                     redirect(301, /cases/open)
#                       cases_responder_root GET    /cases(.:format)                                                     redirect(301, /cases/open)
#                        cases_approver_root GET    /cases(.:format)                                                     redirect(301, /cases/open)
#                                            GET    /cases/new(.:format)                                                 cases#new
#                                   new_case GET    /cases/new/:correspondence_type(.:format)                            cases#new {:correspondence_type=>""}
#                 new_linked_cases_for_cases GET    /cases/new_linked_cases_for(.:format)                                cases#new_linked_cases_for
#                                 close_case GET    /cases/:id/close(.:format)                                           cases#close
#                      closure_outcomes_case GET    /cases/:id/closure_outcomes(.:format)                                cases#closure_outcomes
#                     respond_and_close_case GET    /cases/:id/respond_and_close(.:format)                               cases#respond_and_close
#                               closed_cases GET    /cases/closed(.:format)                                              cases#closed_cases
#                       confirm_destroy_case GET    /cases/:id/confirm_destroy(.:format)                                 cases#confirm_destroy
#                          edit_closure_case GET    /cases/:id/edit_closure(.:format)                                    cases#edit_closure
#                             incoming_cases GET    /cases/incoming(.:format)                                            cases#incoming_cases
#                         root_my_open_cases GET    /cases/my_open(.:format)                                             redirect(301, /cases/my_open/in_time)
#                              my_open_cases GET    /cases/my_open/:tab(.:format)                                        cases#my_open_cases
#                                 open_cases GET    /cases/open(.:format)                                                cases#open_cases
#                          case_open_in_time GET    /cases/:case_id/open/in_time(.:format)                               redirect(301, /cases/open)
#                             case_open_late GET    /cases/:case_id/open/late(.:format)                                  redirect(301, /cases/open)
#                       process_closure_case PATCH  /cases/:id/process_closure(.:format)                                 cases#process_closure
#                process_date_responded_case PATCH  /cases/:id/process_date_responded(.:format)                          cases#process_date_responded
#             process_respond_and_close_case PATCH  /cases/:id/process_respond_and_close(.:format)                       cases#process_respond_and_close
#                        update_closure_case PATCH  /cases/:id/update_closure(.:format)                                  cases#update_closure
#                      record_late_team_case PATCH  /cases/:id/record_late_team(.:format)                                cases#record_late_team
#                               respond_case GET    /cases/:id/respond(.:format)                                         cases#respond
#                       confirm_respond_case PATCH  /cases/:id/confirm_respond(.:format)                                 cases#confirm_respond
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
#                  remove_pit_extension_case PATCH  /cases/:id/remove_pit_extension(.:format)                            cases#remove_pit_extension
#                         new_case_link_case GET    /cases/:id/new_case_link(.:format)                                   cases#new_case_link
#                 execute_new_case_link_case POST   /cases/:id/execute_new_case_link(.:format)                           cases#execute_new_case_link
#                       destroy_link_on_case DELETE /cases/:id/destroy_link/:linked_case_number(.:format)                cases#destroy_case_link
#                progress_for_clearance_case PATCH  /cases/:id/progress_for_clearance(.:format)                          cases#progress_for_clearance
#                    new_overturned_ico_case GET    /cases/:id/new_overturned_ico(.:format)                              cases#new_overturned_ico
#                   extend_sar_deadline_case GET    /cases/:id/extend_sar_deadline(.:format)                             cases#extend_sar_deadline
#           execute_extend_sar_deadline_case PATCH  /cases/:id/execute_extend_sar_deadline(.:format)                     cases#execute_extend_sar_deadline
#         remove_sar_deadline_extension_case PATCH  /cases/:id/remove_sar_deadline_extension(.:format)                   cases#remove_sar_deadline_extension
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
#                                 admin_root GET    /admin(.:format)                                                     redirect(301, /admin/cases)
#                             new_admin_case GET    /admin/cases/new/:correspondence_type(.:format)                      admin/cases#new {:correspondence_type=>""}
#                                admin_cases GET    /admin/cases(.:format)                                               admin/cases#index
#                                            POST   /admin/cases(.:format)                                               admin/cases#create
#                                            GET    /admin/cases/new(.:format)                                           admin/cases#new
#                            edit_admin_case GET    /admin/cases/:id/edit(.:format)                                      admin/cases#edit
#                                 admin_case GET    /admin/cases/:id(.:format)                                           admin/cases#show
#                                            PATCH  /admin/cases/:id(.:format)                                           admin/cases#update
#                                            PUT    /admin/cases/:id(.:format)                                           admin/cases#update
#                                            DELETE /admin/cases/:id(.:format)                                           admin/cases#destroy
#                                admin_users GET    /admin/users(.:format)                                               admin/users#index
#                      admin_dashboard_cases GET    /admin/dashboard/cases(.:format)                                     admin/dashboard#cases
#                   admin_dashboard_feedback GET    /admin/dashboard/feedback(.:format)                                  admin/dashboard#feedback
#                  admin_dashboard_exception GET    /admin/dashboard/exception(.:format)                                 admin/dashboard#exception
#             admin_dashboard_search_queries GET    /admin/dashboard/search_queries(.:format)                            admin/dashboard#search_queries
#               admin_dashboard_list_queries GET    /admin/dashboard/list_queries(.:format)                              admin/dashboard#list_queries
#                  confirm_destroy_team_user GET    /teams/:team_id/users/:id/confirm_destroy(.:format)                  users#confirm_destroy
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
#                                  new_users GET    /users/new(.:format)                                                 users#new
#                                 edit_users GET    /users/edit(.:format)                                                users#edit
#                                      users GET    /users(.:format)                                                     users#show
#                                            PATCH  /users(.:format)                                                     users#update
#                                            PUT    /users(.:format)                                                     users#update
#                                            DELETE /users(.:format)                                                     users#destroy
#                                            POST   /users(.:format)                                                     users#create
#                                 user_teams GET    /users/:user_id/teams(.:format)                                      teams#index
#                                            GET    /users(.:format)                                                     users#index
#                                            POST   /users(.:format)                                                     users#create
#                                   new_user GET    /users/new(.:format)                                                 users#new
#                                  edit_user GET    /users/:id/edit(.:format)                                            users#edit
#                                       user GET    /users/:id(.:format)                                                 users#show
#                                            PATCH  /users/:id(.:format)                                                 users#update
#                                            PUT    /users/:id(.:format)                                                 users#update
#                                            DELETE /users/:id(.:format)                                                 users#destroy
#                                      stats GET    /stats(.:format)                                                     stats#index
#                             stats_download GET    /stats/download/:id(.:format)                                        stats#download
#                       stats_download_audit GET    /stats/download_audit(.:format)                                      stats#download_audit
#               stats_download_custom_report GET    /stats/download_custom_report/:id(.:format)                          stats#download_custom_report
#                               stats_custom GET    /stats/custom(.:format)                                              stats#custom
#                 stats_create_custom_report POST   /stats/create_custom_report(.:format)                                stats#create_custom_report
#                                     search GET    /search(.:format)                                                    cases#search
#                                       ping GET    /ping(.:format)                                                      heartbeat#ping
#                                healthcheck GET    /healthcheck(.:format)                                               heartbeat#healthcheck
#                                       root GET    /                                                                    redirect(301, /users/sign_in)
#
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

  scope :cases, module: 'cases' do
    # Each case type gets its own controller for new and create
    # as the behaviours are all different and different parameters are passed
    resources :fois, only: [:new, :create], controller: 'cases/foi', as: :case_foi_standards
    resources :icos, only: [:new, :create], controller: 'cases/ico', as: :case_icos do
    end
    resources :ico_fois, only: [:new, :create], controller: 'cases/ico_foi', as: :case_ico_fois do
    end
    resources :ico_sars, only: [:new, :create], controller: 'cases/ico_sar', as: :case_ico_sars do
    end
    resources :sars, only: [:new, :create], controller: 'cases/sar', as: :case_sars do
    end

    resources :overturned_ico_fois, only: [:create], controller: 'cases/overturned_foi', as: :case_overturned_fois do
      get :new, on: :member
    end

    resources :overturned_ico_sars, only: [:create], controller: 'cases/overturned_sar', as: :case_overturned_sars do
      get :new, on: :member
    end

    # Search and Filtering
    resources :search, only: [:index], as: :search_cases

    resources :filter, path: '/' do
      get 'my_open', on: :collection, to: redirect('filter/my_open/in_time'), as: :root_my_open
      get 'my_open/:tab' => 'filter#my_open', on: :collection, as: :my_open
      get 'open' => 'filter#open', on: :collection, as: :open
      get 'open/in_time', to: redirect('filter/open')
      get 'open/late',    to: redirect('filter/open')
      get 'closed' => 'filter#closed', on: :collection
      get 'deleted' => 'filter/#deleted', on: :collection
      get 'incoming' => 'filter#incoming', on: :collection
      post  :filter, on: :collection
    end

    resources :ico do
      patch 'record_late_team'#, on: :member - not sure why member not working
    end
  end

  resources :cases, controller: 'cases/base', except: [:create] do
    # General
    get :confirm_destroy, on: :member


    # Case behaviours

    resources :closure do
      get 'close', on: :member
      get 'edit_closure', on: :member, as: :edit_closure
      patch 'process_closure', on: :member
      patch 'update_closure', on: :member
      get 'closure_outcomes', on: :member
      get 'respond_and_close', on: :member
      patch 'process_respond_and_close', on: :member
      patch 'process_date_responded', on: :member
      get 'respond', on: :member
      patch 'confirm_respond', on: :member
    end

    resources :clearance do
      patch 'unflag_for_clearance' => 'cases/base#unflag_for_clearance', on: :member
      patch 'unflag_taken_on_case_for_clearance' => 'cases/base#unflag_taken_on_case_for_clearance', on: :member
      patch 'flag_for_clearance' => 'cases/base#flag_for_clearance', on: :member
      get 'remove_clearance' => 'cases#remove_clearance', on: :member
      patch :request_further_clearance, on: :member
      patch 'progress_for_clearance' => 'cases/base#progress_for_clearance', on: :member
    end

    resources :link do
      get 'new_linked_cases_for', on: :collection
      get :new_case_link, on: :member
      post :execute_new_case_link, on: :member
      delete 'destroy_link/:linked_case_number' => 'cases/base#destroy_case_link' , on: :member, as: 'destroy_link_on'
    end

    resources :pit_extension, only: [:new, :create] do
      delete :destroy, on: :collection
    end

    resources :sar_extension, only: [:new, :create] do
      delete :destroy, on: :collection
    end

    resources :approval, only: [:new, :create]

    resources :response do
      get 'upload_responses', on: :member
      patch 'upload_responses',
            action: :execute_upload_responses,
            on: :member
      get 'upload_response_and_approve', on: :member
      patch 'upload_response_and_approve',
            action: :execute_upload_response_and_approve,
            on: :member
      get 'upload_response_and_return_for_redraft', on: :member
      patch 'upload_response_and_return_for_redraft',
            action: :execute_upload_response_and_return_for_redraft,
            on: :member
    end

    resources :amendment, only: [:new, :create]

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
      get :assign_to_team, on: :collection, as: 'assign_to_responder_team'
    end

    resources :case_attachments, path: 'attachments'

    resources :messages, only: :create

    resources :case_attachments, path: 'attachments', only: [:destroy] do
      get 'download', on: :member
    end
  end

  authenticated :user, ->(u) { u.admin? } do
    namespace :admin do
      root to: redirect('/admin/cases')
      resources :cases do
        get ':correspondence_type',
            action: :new,
            on: :new,
            as: '',
            defaults: { correspondence_type: '' }
      end
      get 'users' => 'users#index'
      get '/dashboard/cases' => 'dashboard#cases'
      get '/dashboard/feedback' => 'dashboard#feedback'
      get '/dashboard/exception' => 'dashboard#exception'
      get '/dashboard/search_queries' => 'dashboard#search_queries'
      get '/dashboard/list_queries' => 'dashboard#list_queries'
    end
  end

  resources :teams do
    resources :users do
      get 'confirm_destroy', on: :member
    end

    get 'business_areas_covered' => 'teams#business_areas_covered',
        as: 'areas_covered_by', on: :member
    post 'create_areas_covered'=> 'teams#create_business_areas_covered',
        as: 'create_areas_covered_by', on: :member
    delete 'destroy_business_area' => 'teams#destroy_business_area', on: :member
    patch 'update_business_area' => 'teams#update_business_area', on: :member
    get 'update_business_area_form' => 'teams#update_business_area_form', on: :member
  end

  resource :users

  authenticate :user do
    resources :users do
      resources :teams, only: :index
    end
  end

  resources :stats, only: [:index, :show, :new, :create] do
    get 'download_custom/:id', action: :download_custom, on: :collection, as: :download_custom
    get :download_audit, on: :collection
  end


  #get '/search' => 'cases#search'

  get 'ping', to: 'heartbeat#ping', format: :json

  get 'healthcheck',    to: 'heartbeat#healthcheck',  as: 'healthcheck', format: :json

  root to: redirect('/users/sign_in')
end
