Rails.application.routes.draw do
  namespace :admin do
    resources :users, only: [:index, :edit, :update]
  end
devise_for :users, controllers: { sessions: 'users/sessions', registrations: 'users/registrations' }  # Using custom SessionsController and RegistrationsController

  resources :users, only: [ :show, :edit, :update ], path: "profile"

  resources :categories do
    resources :posts, only: [ :index ]  # Nest posts under categories
  end

resources :posts do
resources :comments do
    resources :replies, only: [:create], controller: 'comments'
end
end

  resources :tags, only: [ :index, :show ]

  resources :notifications, only: [:index, :destroy] do
    member do
      post :mark_as_read
    end
    collection do
      post :mark_all_as_read
      delete :clear
    end
  end

  root "home#index"

  get "search", to: "search#index", as: "search"
  get "about", to: "pages#about", as: "about"
  get "contact", to: "pages#contact", as: "contact"
  post "contact", to: "pages#submit_contact"

  get "up" => "rails/health#show", as: :rails_health_check
end

