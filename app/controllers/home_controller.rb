class HomeController < ApplicationController
  def index
    @posts = Post.includes(:user, :category).order(created_at: :desc)
    @categories = Category.all
    @tags = Tag.all # Assuming you have a Tag model
  end
end
