class HomeController < ApplicationController
  # Allow homepage for all users, but require authentication for forum
  skip_before_action :authenticate_user!, only: [ :index ]
  skip_after_action :verify_policy_scoped, only: [ :index ]
  skip_after_action :verify_authorized, only: [ :index ]
  before_action :authenticate_user!, only: [ :post_index ]

  def index
    # Simple landing page - no posts loading needed
  end

  def post_index
    # Only authenticated users can access the forum
    @posts = policy_scope(Post)
      .includes(:user, :category)
      .order(created_at: :desc)
      .page(params[:page])
      .per(10)

    @categories = Category.all
    @tags = Tag.all
  end

end
