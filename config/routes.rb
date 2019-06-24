require 'sidekiq/web'

Rails.application.routes.draw do

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

  # Case Concerns
  # Legacy routes that are awaiting transition to more idiomatic
  # controller/routing structures
  concern :closable do
    member do
      get :close
      get :edit_closure
      get :closure_outcomes
      get :respond_and_close
      get :respond
    end

    collection do
      patch :process_closure
      patch :update_closure
      patch :process_respond_and_close
      patch :process_date_responded
      patch :confirm_respond
    end
  end


  # Case Create & Case Specific Actions
  scope :cases, module: 'cases' do
    resources :fois, only: [:new, :create], controller: 'foi', as: :case_foi_standards do
      concerns :closable
    end

    resources :sars, only: [:new, :create], controller: 'sar', as: :case_sar_standards do
      concerns :closable
    end

    resources :icos, only: [:new, :create], controller: 'ico', as: :case_icos do
      concerns :closable
    end

    resources :ico_fois, only: [:new, :create], controller: 'ico_foi', as: :case_ico_fois do
      concerns :closable
    end

    resources :ico_sars, only: [:new, :create], controller: 'ico_sar', as: :case_ico_sars do
      concerns :closable
    end

    resources :overturned_ico_fois, only: [:create], controller: 'overturned_foi', as: :case_overturned_fois do
      get :new, on: :member
      concerns :closable
    end

    resources :overturned_ico_sars, only: [:create], controller: 'overturned_sar', as: :case_overturned_sars do
      get :new, on: :member
      concerns :closable
    end

    resources :offender_sars, only: [:new, :create], controller: 'offender_sar', as: :case_sar_offenders do
      get 'cancel', on: :collection
      get '/(:step)', on: :collection, to: 'offender_sar#new', as: 'step'
      concerns :closable
    end

    resources :ico do
      patch 'record_late_team'#, on: :member - not sure why member not working
      concerns :closable
    end
  end

  # Case Search and Filtering
  scope :cases, module: 'cases' do
    resource :search, only: [:show]

    resource :filter, only: [:show], path: '/' do
      get 'my_open', to: redirect('/cases/my_open/in_time'), as: :root_my_open
      get 'my_open/:tab' => 'filters#my_open', as: :my_open
      get 'open' => 'filters#open'
      get 'open/in_time', to: redirect('/cases/open')
      get 'open/late',    to: redirect('/cases/open')
      get 'closed' => 'filters#closed'
      get 'deleted' => 'filters#deleted'
      get 'incoming' => 'filters#incoming'
      get '/' => 'filters#show'
    end
  end

  # Case Actions (general)
  resources :cases, except: [:index, :create] do
    get :confirm_destroy, on: :member
  end

  # Case Behaviours
  resources :cases, module: 'cases' do
    resources :links, except: [:index, :edit, :update]

    resources :pit_extensions, only: [:new, :create]
    resource :pit_extension, only: [:destroy]

    resources :sar_extensions, only: [:new, :create]
    resource :sar_extension, only: [:destroy]

    resources :approvals, only: [:new, :create]

    resource :responses, only: [:create] do
      get 'new/:response_action', to: 'responses#new', as: 'new'
    end

    resources :amendments, only: [:new, :create]

    resources :messages, only: [:create]

    resources :attachments, only: [:destroy] do
      get 'download', on: :member
    end

    resource :clearances, as: '' do
      get :remove_clearance
      patch :unflag_for_clearance
      patch :unflag_taken_on_case_for_clearance
      patch :request_further_clearance
      patch :progress_for_clearance
      patch :flag_for_clearance
    end
  end

  # Case Behaviours (awaiting move to module Cases)
  resources :cases do
    resources :assignments, except: :create  do
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
        get :assign_to_team, as: :assign_to_responder_team
      end
    end
  end

  # Stats Reporting and Performance
  resources :stats, only: [:index, :show, :new, :create] do
    get 'download_custom/:id', action: :download_custom, on: :collection, as: :download_custom
    get :download_audit, on: :collection
  end

  resource :users

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

  authenticate :user do
    resources :users do
      resources :teams, only: :index
    end
  end

  get 'ping', to: 'heartbeat#ping', format: :json
  get 'healthcheck',    to: 'heartbeat#healthcheck',  as: 'healthcheck', format: :json
  post '/feedback' => 'feedback#create'

  root to: redirect('/users/sign_in')
end
