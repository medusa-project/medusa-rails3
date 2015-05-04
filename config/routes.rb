MedusaCollectionRegistry::Application.routes.draw do

  resources :static_pages, only: [:show, :edit, :update], param: :key do
    member do
      post :deposit_files
      post :feedback
      post :request_training
    end
  end
  match '/auth/:provider/callback', to: 'sessions#create', via: [:get, :post]
  match '/login', to: 'sessions#new', as: :login, via: [:get, :post]
  match '/logout', to: 'sessions#destroy', as: :logout, via: [:get, :post]
  match '/unauthorized', to: 'sessions#unauthorized', as: :unauthorized, via: [:get, :post]
  match '/unauthorized_net_id', to: 'sessions#unauthorized_net_id', as: :unauthorized_net_id, via: [:get, :post]

  #This lets us start up in a mode where only a down page is shown
  if ENV['MEDUSA_DOWN'] == 'true'
    match '*path' => redirect('/static_pages/down', status: 307), via: :all
    root to: 'static_pages#show', key: 'down'
  else
    root to: 'static_pages#show', key: 'landing'
  end

  concern :eventable, Proc.new { member { get 'events' } }
  concern :red_flaggable, Proc.new { member { get 'red_flags' } }
  concern :public, Proc.new { member { get 'public' } }
  concern :assessable, Proc.new { member { get 'assessments' } }
  concern :attachable, Proc.new { member { get 'attachments' } }
  concern :downloadable, Proc.new { member { get 'download' } }
  concern :collection_indexer, Proc.new { member { get 'collections' } }
  concern :fixity_checkable, Proc.new { member { post 'fixity_check' } }

  resources :collections, concerns: %i(eventable red_flaggable public assessable attachable)

  resources :repositories, concerns: %i(eventable red_flaggable assessable collection_indexer) do
    get 'edit_ldap_admins', on: :collection
    put 'update_ldap_admin', on: :member
  end
  resources :institutions
  resources :assessments, only: [:show, :edit, :update, :new, :create, :destroy]
  resources :attachments, only: [:show, :edit, :update, :new, :create, :destroy], concerns: :downloadable

  resources :events do
    get :autocomplete_user_email, on: :collection
  end

  [:file_groups, :external_file_groups, :bit_level_file_groups, :object_level_file_groups].each do |file_group_type|
    resources file_group_type, only: [:show, :edit, :update, :new, :create, :destroy],
              concerns: %i(eventable red_flaggable public assessable attachable) do
      %w(create_cfs_fits create_virus_scan create_amazon_backup fixity_check create_initial_cfs_assessment).each do |action|
        post action, on: :member
      end if file_group_type == :bit_level_file_groups
      post 'ingest', on: :member if file_group_type == :external_file_groups
      post 'bulk_amazon_backup', on: :collection
    end
  end

  resources :red_flags, only: [:show, :edit, :update] do
    post 'unflag', on: :member
  end

  resources :producers
  resources :access_systems, concerns: :collection_indexer
  resources :package_profiles, concerns: :collection_indexer
  resources :virus_scans, only: :show
  resources :scheduled_events, only: [:edit, :update, :create, :destroy] do
    %w(complete cancel).each { |action| post action, on: :member }
  end

  resources :cfs_files, only: :show, concerns: %i(public downloadable eventable fixity_checkable) do
    %w(public_download public_view create_fits_xml fits view preview_image public_preview_image preview_video).each { |action| get action, on: :member }
  end
  get 'cfs_files/:id/preview_iiif_image/*iiif_parameters', to: 'cfs_files#preview_iiif_image', as: 'preview_iiif_image_cfs_file'
  get 'cfs_files/:id/public_preview_iiif_image/*iiif_parameters', to: 'cfs_files#public_preview_iiif_image', as: 'public_preview_iiif_image_cfs_file'

  resources :cfs_directories, only: :show, concerns: %i(public fixity_checkable eventable) do
    %w(create_fits_for_tree export export_tree).each { |action| post action, on: :member }
  end
  resources :content_types, only: [] do
    get :cfs_files, on: :member
    post :fits_batch, on: :member
  end
  resources :file_extensions, only: [] do
    get :cfs_files, on: :member
    post :fits_batch, on: :member
  end
  resources :file_format_profiles
  resources :searches, only: [] do
    post :filename, on: :collection
    get :filename, on: :collection
  end
  resources :accruals, only: [] do
    get :update_display, on: :member
    post :submit, on: :collection
  end
  resources :uuids, only: [:show]

  match '/dashboard', to: 'dashboard#show', as: :dashboard, via: [:get, :post]

  namespace :book_tracker do
    match 'items', to: 'items#index', as: :items, via: [:get, :post]
    match 'items/:id', to: 'items#show', as: :item, via: :get
    resources 'tasks', only: 'index'

    match 'check-google', to: 'tasks#check_google', via: 'post',
          as: 'check_google'
    match 'check-hathitrust', to: 'tasks#check_hathitrust', via: 'post',
          as: 'check_hathitrust'
    match 'check-internet-archive', to: 'tasks#check_internet_archive',
          via: 'post', as: 'check_internet_archive'
    match 'import', to: 'tasks#import', via: 'post'
  end

  match "/delayed_job" => DelayedJobWeb, :anchor => false, via: [:get, :post]

end
