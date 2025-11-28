require "sidekiq/web"

Rails.application.routes.draw do
  resources :contacts, except: :show do
    get "/new_details", on: :collection, to: "contacts#new_details"
    post "/new_details", on: :collection, to: "contacts#new_details"
  end

  get "/contacts_search", to: "contacts#contacts_search"

  devise_for :users, controllers: {
    passwords: "passwords",
    omniauth_callbacks: "omniauth_callbacks",
  }

  gnav = Settings.global_navigation

  authenticated :user, ->(u) { u.manager? } do
    root to: redirect(gnav.default_urls.manager), as: :manager_root
  end

  authenticated :user, ->(u) { u.responder? } do
    root to: redirect(gnav.default_urls.responder), as: :responder_root
  end

  authenticated :user, ->(u) { u.approver? } do
    root to: redirect(gnav.default_urls.approver), as: :approver_root
  end

  authenticated :user, ->(u) { u.team_admin? } do
    root to: redirect(gnav.default_urls.team_admin), as: :team_admin_root
  end

  authenticate :user, ->(u) { u.admin? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  # Case Concerns
  # Legacy routes that are awaiting transition to more idiomatic
  # controller/routing structures
  concern :closable_actions do
    member do
      get :close
      get :edit_closure
      get :closure_outcomes
      get :respond_and_close
      get :respond

      patch :process_closure
      patch :update_closure
      patch :process_respond_and_close
      patch :process_date_responded
      patch :confirm_respond
    end
  end

  # Case Create & Case Specific Actions (use polymorphic_path to generate url)
  scope :cases, module: "cases" do
    # Setup closable routing first. We may have a mis-match between the
    # Case Model name e.g. Case::OverturnedICO::SAR and the corresponding
    # view folder which uses the CorrespondenceType abbreviation (an arbitrary
    # string e.g. overturned_sar). This legacy naming is why the routing for
    # different Case types is more verbose.
    correspondence_type_resources = {
      foi: "foi_standard", # views are in /foi
      sar: "sar_standard", # views are in /sar
      sar_internal_review: "sar_internal_review", # views are in /sar
      offender_sar: "sar_offender",
      offender_sar_complaint: "sar_offender_complaint",
      ico: "ico",
      ico_foi: "ico_foi",
      ico_sar: "ico_sar",
      overturned_ico_foi: "overturned_ico_foi", # views are in /overturned_foi
      overturned_ico_sar: "overturned_ico_sar", # views are in /overturned_sar
    }

    # Standard routes, note use of `resources` and singular custom named routes
    only = %i[index new edit update]

    correspondence_type_resources.each do |resource, model_name|
      resources resource.to_s.pluralize, only:, controller: resource, as: "case_#{model_name}" do
        concerns :closable_actions
      end

      resource resource.to_s.pluralize, only: [:create], controller: resource, as: "case_#{model_name}"
    end

    resources :offender_sars, only:, controller: "offender_sar", as: :case_sar_offender do
      get "cancel", on: :collection
      get "/(:step)", on: :collection, to: "offender_sar#new", as: "step"
      get "/edit/:step", on: :member, to: "offender_sar#edit", as: "edit_step"
      post "/update", on: :member, to: "offender_sar#update", as: "update_step"
      get "/move_case_back", on: :member, to: "offender_sar#move_case_back", as: "move_case_back"
      patch "/move_case_back", on: :member, to: "offender_sar#confirm_move_case_back", as: "confirm_move_case_back"
      get "/record_reason_for_lateness", on: :member, to: "offender_sar#record_reason_for_lateness", as: "record_reason_for_lateness"
      patch "/record_reason_for_lateness", on: :member, to: "offender_sar#confirm_record_reason_for_lateness", as: "confirm_record_reason_for_lateness"
      get "/accepted_date_received", on: :member, to: "offender_sar#accepted_date_received", as: "accepted_date_received"
      patch "/accepted_date_received", on: :member, to: "offender_sar#confirm_accepted_date_received", as: "confirm_accepted_date_received"
      patch "/confirm_update_partial_flags", on: :member, to: "offender_sar#confirm_update_partial_flags", as: "confirm_update_partial_flags"
      patch "/confirm_sent_to_sscl", on: :member, to: "offender_sar#confirm_sent_to_sscl", as: "confirm_sent_to_sscl"
      member do
        patch "/transitions/:transition_name", to: "offender_sar#transition", as: :transition
      end
    end

    resources :fois, only:, controller: "foi", as: :case_foi do
      get "/send_back", on: :member, to: "foi#send_back", as: "send_back"
      patch "/send_back", on: :member, to: "foi#confirm_send_back", as: "confirm_send_back"
    end

    resources :offender_sar_complaints, only:, controller: "offender_sar_complaint", as: :case_sar_offender_complaint do
      get "cancel", on: :collection
      get "/(:step)", on: :collection, to: "offender_sar_complaint#new", as: "step"
      post "/offender_sar/(:number)", on: :collection, to: "offender_sar_complaint#start_complaint", as: "start_complaint"
      get "/reopen", on: :member, to: "offender_sar_complaint#reopen", as: "reopen"
      patch "/reopen", on: :member, to: "offender_sar_complaint#confirm_reopen", as: "confirm_reopen"
      get "/edit/:step", on: :member, to: "offender_sar_complaint#edit", as: "edit_step"
      post "/update", on: :member, to: "offender_sar_complaint#update", as: "update_step"
      member do
        patch "/transitions/:transition_name", to: "offender_sar_complaint#transition", as: :transition
      end
    end

    resources :sar_internal_review, only:, controller: "sar_internal_review", as: :case_sar_internal_review do
      get "/(:step)", on: :collection, to: "sar_internal_review#new", as: "step"
      get "/edit", on: :member, to: "sar_internal_review#edit"
      post "/update", on: :member, to: "sar_internal_review#update"
    end

    resources :icos, only:, controller: "ico", as: :case_ico do
      get "new_linked_cases_for", on: :collection, to: "ico#new_linked_cases_for"
      patch "record_late_team", on: :member, to: "ico#record_late_team"
      get "record_further_action", on: :member, to: "ico#record_further_action"
      patch "record_further_action", on: :member, to: "ico#confirm_record_further_action"
      get "require_further_action", on: :member, to: "ico#require_further_action"
      patch "require_further_action", on: :member, to: "ico#confirm_require_further_action"
      get "record_sar_complaint_outcome", on: :member, to: "ico_sar#record_complaint_outcome"
      patch "record_sar_complaint_outcome", on: :member, to: "ico_sar#confirm_record_complaint_outcome"
    end

    resources :overturned_ico_fois, only: [:create], controller: "overturned_ico_foi", as: :case_overturned_ico_fois do
      get "new/:id", as: "new", to: "overturned_ico_foi#new", on: :collection
    end

    resources :overturned_ico_sars, only: [:create], controller: "overturned_ico_sar", as: :case_overturned_ico_sars do
      get "new/:id", as: "new", to: "overturned_ico_sar#new", on: :collection
    end

    # Additional FOI type routes required for closable actions generated by polymorphic_path
    %w[foi_compliance_review foi_timeliness_review].each do |foi_type|
      resources foi_type, only: [], controller: "foi", as: "case_#{foi_type}" do
        concerns :closable_actions
      end
    end
  end

  # Case Search and Filtering
  scope :cases, module: "cases" do
    resource :search, only: [:show]

    resource :filter, only: [:show], path: "/" do
      get "my_open", to: redirect("/cases/my_open/in_time"), as: :root_my_open
      get "my_open/:tab" => "filters#my_open", as: :my_open
      get "retention", to: redirect("/cases/retention/pending_removal"), as: :root_retention
      get "retention/:tab" => "filters#retention", as: :retention
      get "open" => "filters#open"
      get "open/in_time", to: redirect("/cases/open")
      get "open/late",    to: redirect("/cases/open")
      get "closed" => "filters#closed"
      get "deleted" => "filters#deleted"
      get "incoming" => "filters#incoming"
      get "/" => "filters#show"
    end
  end

  resources :retention_schedules, only: %i[edit update] do
    patch :bulk_update, on: :collection
  end

  # Case Actions (general)
  resources :cases, only: %i[new show destroy] do
    get :confirm_destroy, on: :member
  end

  # Case Behaviours
  resources :cases, module: "cases" do
    resources :links, except: %i[show index edit update]

    resources :pit_extensions, only: %i[new create]
    resource :pit_extensions, only: [:destroy]

    resources :sar_extensions, only: %i[new create]
    resource :sar_extensions, only: [:destroy]

    resources :stop_the_clocks, only: %i[new create]

    resources :approvals, only: %i[new create]

    resource :responses, only: [:create] do
      get "new/:response_action", to: "responses#new", as: "new"
    end

    resources :amendments, only: %i[new create]

    resources :messages, only: [:create]
    resources :notes, only: [:create]

    resources :attachments, only: %i[show destroy new create] do
      get "download", on: :member
    end

    resource :clearances, as: "" do
      get :remove_clearance
      patch :unflag_for_clearance
      patch :unflag_taken_on_case_for_clearance
      patch :request_further_clearance
      patch :progress_for_clearance
      patch :flag_for_clearance
    end

    resource :cover_page, only: [:show], path: "cover-page"

    resources :data_request_areas do
      member do
        get :send_email
        post :send_email
      end

      resources :data_requests

      resource :commissioning_documents, only: %i[new create] do
        member do
          get :download
          post :send_email
        end
      end
    end

    resource :letters, only: %i[new show], path: "letters/:type"
  end

  # Case Behaviours (awaiting move to module Cases)
  resources :cases do
    resources :assignments, except: :create do
      member do
        get :reassign_user
        get :assign_to_new_team

        patch :accept
        patch :accept_or_reject
        patch :execute_reassign_user
        patch :execute_assign_to_new_team
        patch :take_case_on
        patch :unaccept
      end

      collection do
        get :select_team
        get :assign_to_team_member
        get :assign_to_team, as: :assign_to_responder_team
        get :assign_to_vetter
        post :execute_assign_to_team_member
      end
    end
  end

  # Stats Reporting and Performance
  resources :stats, only: %i[index show new create] do
    get "download_custom/:id", action: :download_custom, on: :collection, as: :download_custom
    get :download_audit, on: :collection
  end

  resource :users

  resources :teams do
    resources :users do
      get "confirm_destroy", on: :member
    end

    get "business_areas_covered" => "teams#business_areas_covered",
        as: "areas_covered_by", on: :member
    post "create_areas_covered" => "teams#create_business_areas_covered",
         as: "create_areas_covered_by", on: :member
    delete "destroy_business_area" => "teams#destroy_business_area", on: :member
    patch "update_business_area" => "teams#update_business_area", on: :member
    get "update_business_area_form" => "teams#update_business_area_form", on: :member
    get "move_to_business_group" => "teams#move_to_business_group", on: :member
    get "move_to_business_group_form" => "teams#move_to_business_group_form", on: :member
    get "move_to_directorate" => "teams#move_to_directorate", on: :member
    get "move_to_directorate_form" => "teams#move_to_directorate_form", on: :member
    post "update_directorate" => "teams#update_directorate", on: :member
    post "update_business_group" => "teams#update_business_group", on: :member
    get "join_teams" => "teams#join_teams", on: :member
    get "join_teams_form" => "teams#join_teams_form", on: :member
    post "join_teams" => "teams#join_target_team", on: :member
  end

  authenticated :user, ->(u) { u.admin? } do
    namespace :admin do
      root to: redirect("/admin/cases")
      resources :cases, only: :index
      get "users" => "users#index"
      get "/dashboard/cases" => "dashboard#cases"
      get "/dashboard/feedback" => "dashboard#feedback"
      get "/dashboard/feedback/:year" => "dashboard#feedback_year", as: :dashboard_feedback_year
      get "/dashboard/exception" => "dashboard#exception"
      get "/dashboard/search_queries" => "dashboard#search_queries"
      get "/dashboard/list_queries" => "dashboard#list_queries"
      get "/dashboard/system" => "dashboard#system"
    end
  end

  authenticate :user do
    resources :users do
      resources :teams, only: :index
    end
  end

  namespace :api do
    post "rpi" => "rpi#create"
    post "rpi/v2" => "rpi_v2#create"
  end

  get "rpi/:target/:id" => "rpi#download", as: :rpi_file_download

  if Rails.env.development?
    post "dev_s3_uploader" => "dev_s3_uploader#create"
  end

  get "ping", to: "heartbeat#ping", format: :json
  get "healthcheck", to: "heartbeat#healthcheck", as: "healthcheck", format: :json
  post "/feedback" => "feedback#create"
  get "/accessibility" => "pages#accessibility"

  get "/maintenance", to: "application#maintenance_mode"

  root to: redirect("/users/sign_in")
end
