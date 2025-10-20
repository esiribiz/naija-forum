class HomeController < ApplicationController
  # Allow homepage and forum access for all users (guests and logged-in)
  skip_before_action :authenticate_user!, only: [ :index, :post_index ]
  skip_after_action :verify_policy_scoped, only: [ :index, :post_index ]
  skip_after_action :verify_authorized, only: [ :index, :post_index ]

  def index
    # Simple landing page - no posts loading needed
  end

  def post_index
    # For guests, show all posts; for logged-in users, apply policy scope
    if user_signed_in?
      @posts = policy_scope(Post)
        .includes(:user, :category)
        .order(created_at: :desc)
        .page(params[:page])
        .per(10)
    else
      # For guests, show all public posts (you might want to add visibility logic here)
      @posts = Post.includes(:user, :category)
        .order(created_at: :desc)
        .page(params[:page])
        .per(10)
    end

    @categories = Category.all
    @tags = Tag.all
  end

end
