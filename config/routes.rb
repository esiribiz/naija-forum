Rails.application.routes.draw do
  # Admin routes
  namespace :admin do
    root 'dashboard#index'
    get 'dashboard', to: 'dashboard#index'
    
    resources :users do
      collection do
        get :export
      end
      member do
        patch :toggle_admin
        patch :promote_to_moderator
        patch :demote_user
        patch :ban
        patch :unban
        patch :toggle_suspend
        patch :update_role
      end
    end
    
    get 'role_management', to: 'role_management#index'
    post 'role_management/update_role', to: 'role_management#update_role'
    
    resources :posts do
      member do
        patch :toggle_published
      end
    end
    
    resources :comments do
      member do
        patch :approve
        patch :reject
      end
    end
    
    resources :categories
    resources :tags
    
    resources :approved_tags do
      member do
        patch :toggle_active
        patch :toggle_featured
      end
    end
    
    resources :tag_suggestions do
      member do
        patch :approve
        delete :reject
      end
      collection do
        patch :bulk_approve
        delete :bulk_reject
      end
    end
  end
devise_for :users, controllers: { sessions: 'users/sessions', registrations: 'users/registrations' }  # Using custom SessionsController and RegistrationsController
  
  # Backup logout routes (wrapped in devise_scope)
  devise_scope :user do
    get '/simple_logout', to: 'users/sessions#simple_logout', as: 'simple_logout'
    get '/emergency_logout', to: 'users/sessions#emergency_logout', as: 'emergency_logout'
    get '/force_logout', to: 'users/sessions#force_logout', as: 'force_logout'
  end

  resources :users, only: [ :show, :edit, :update ], path: "profile"

  resources :categories do
    resources :posts, only: [ :index ]  # Nest posts under categories
  end

  resources :posts do
    resources :comments do
      member do
        get :cancel_edit
      end
    end
  end

  resources :tags, only: [ :index, :show, :edit, :update ] do
    collection do
      get :suggestions
    end
    member do
      patch :toggle_featured
      patch :toggle_official
    end
  end
  
  resources :approved_tags, only: [:index] do
    collection do
      get :suggestions
    end
  end

  resources :notifications, only: [:index, :destroy] do
    member do
      post :mark_as_read
    end
    collection do
      post :mark_all_as_read
      delete :clear
    end
  end

  # NaijaGlobalNet Pages
  root "home#index"
  get "/forum", to: "home#post_index", as: "forum_home"
  get "/posts", to: "posts#index", as: "posts_page"
  get "/welcome", to: "pages#welcome"
  get "/rules", to: "pages#rules"
  post "/rules/accept", to: "pages#accept_rules"

  get "search", to: "search#index", as: "search"
  get "latest", to: "posts#latest", as: "latest_posts"
  get "popular", to: "posts#popular", as: "popular_posts"
  
  # Tag filtering routes
  get "posts/tagged/:tag_id", to: "posts#index", as: "posts_by_tag"
  get "posts/category/:tag_category", to: "posts#index", as: "posts_by_tag_category"
  get "about", to: "pages#about", as: "about"
  get "contact", to: "pages#contact", as: "contact"
  post "contact", to: "pages#submit_contact"

  get "up" => "rails/health#show", as: :rails_health_check
  
  # API Routes - Currently disabled
  # Uncomment and implement controllers when API is needed
  # namespace :api do
  #   namespace :v1 do
  #     # Posts API
  #     resources :posts do
  #       member do
  #         post :like
  #       end
  #       collection do
  #         get :latest
  #         get :popular
  #       end
  #     end
  #     
  #     # Users API
  #     resources :users, only: [:index, :show, :update] do
  #       member do
  #         get :posts
  #         get :comments
  #       end
  #     end
  #     
  #     # Categories API
  #     resources :categories, only: [:index, :show] do
  #       member do
  #         get :posts
  #       end
  #     end
  #     
  #     # Comments API
  #     resources :comments, only: [:create, :update, :destroy]
  #     
  #     # Search API
  #     get :search, to: 'search#index'
  #     
  #     # Tags API
  #     resources :tags, only: [:index, :show]
  #     
  #     # Notifications API
  #     resources :notifications, only: [] do
  #       collection do
  #         get :unread_count
  #       end
  #     end
  #   end
  # end
  # 
  # # Notifications API (non-versioned for simplicity)
  # namespace :api do
  #   resources :notifications, only: [] do
  #     collection do
  #       get :unread_count
  #     end
  #   end
  # end
end

