Rails.application.routes.draw do
  devise_for :users  # Use default Devise controllers

  resources :users, only: [ :show, :edit, :update ], path: "profile"

  resources :categories do
    resources :posts, only: [ :index ]  # Nest posts under categories
  end

  resources :posts do
    resources :comments, only: [ :create, :destroy ]
  end

  resources :tags, only: [ :index, :show ]


  root "home#index"

  get "search", to: "search#index", as: "search"

  get "up" => "rails/health#show", as: :rails_health_check
end
