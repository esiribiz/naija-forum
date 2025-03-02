Rails.application.routes.draw do
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


  root "home#index"

  get "search", to: "search#index", as: "search"

  get "up" => "rails/health#show", as: :rails_health_check
end

