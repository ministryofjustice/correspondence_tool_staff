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

  post '/feedback' => 'feedback#create'

  scope :cases, module: 'cases' do
    # Case creation per type
    resources :fois, only: [:new, :create], controller: 'foi', as: :case_foi_standards
    resources :sars, only: [:new, :create], controller: 'sar', as: :case_sar_standards
    resources :icos, only: [:new, :create], controller: 'ico', as: :case_icos
    resources :ico_fois, only: [:new, :create], controller: 'ico_foi', as: :case_ico_fois
    resources :ico_sars, only: [:new, :create], controller: 'ico_sar', as: :case_ico_sars

    resources :overturned_ico_fois, only: [:create], controller: 'overturned_foi', as: :case_overturned_fois do
      get :new, on: :member
    end

    resources :overturned_ico_sars, only: [:create], controller: 'overturned_sar', as: :case_overturned_sars do
      get :new, on: :member
    end

    resources :offender_sars, only: [:new, :create], controller: 'offender_sar', as: :case_sar_offenders do
      get 'cancel', on: :collection
      get '/(:step)', on: :collection, to: 'offender_sar#new', as: 'step'
    end

    resources :ico do
      patch 'record_late_team'#, on: :member - not sure why member not working
    end

    # Search and Filtering
    resource :search, only: [:show]
    resource :filter, only: [], path: '/' do
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

  resources :cases, except: [:index, :create] do
    get :confirm_destroy, on: :member
  end

  resources :cases, module: 'cases' do


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

    # @todo: Refactor to be clearer in intent/state transistions
    resources :clearances do
      # @todo: Implement
      # post create (flag_for_clearance)
      # delete destroy (remove_clearance)
      #patch 'update/(:action)', to: 'clearances#update', on: :member, constraint: { action: [progress, extend, unflag]}

      patch 'unflag_for_clearance' => 'cases/base#unflag_for_clearance', on: :member
      patch 'unflag_taken_on_case_for_clearance' => 'cases/base#unflag_taken_on_case_for_clearance', on: :member
      patch :request_further_clearance, on: :member # extend
      patch 'progress_for_clearance' => 'cases/base#progress_for_clearance', on: :member # progress

      patch 'flag_for_clearance' => 'cases/base#flag_for_clearance', on: :member
      get 'remove_clearance' => 'cases#remove_clearance', on: :member
    end

    #new_case_link_case GET    /cases/:id/new_case_link(.:format)                                   cases#new_case_link
    resources :links, except: [:edit, :update] do
      # get 'new_linked_cases_for', on: :collection
      # get :new_case_link, on: :member
      # post :execute_new_case_link, on: :member
      # delete 'destroy_link/:linked_case_number' => 'cases/base#destroy_case_link' , on: :member, as: 'destroy_link_on'
    end

    resources :pit_extensions, only: [:new, :create]
    resource :pit_extension, only: [:destroy]

    resources :sar_extensions, only: [:new, :create]
    resource :sar_extension, only: [:destroy]

    resources :approval, only: [:new, :create]

    resource :responses, only: [:create] do
      get 'new/:response_action', to: 'responses#new', as: 'new'
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

    resources :messages, only: [:create]

    resources :attachments, path: 'attachments', only: [:destroy] do
      get 'download', on: :member
    end
  end

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

  root to: redirect('/users/sign_in')
end
