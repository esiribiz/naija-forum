class HomeController < ApplicationController
  def index
    @posts = policy_scope(Post)
    .includes(:user, :category)
    .order(created_at: :desc)
    .page(params[:page])
    .per(10)
    @categories = Category.all
    @tags = Tag.all # Assuming you have a Tag model
  end
end
