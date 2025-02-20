class SearchController < ApplicationController
  def index
    @query = params[:query]

    if @query.present?
      # Searching across multiple models (e.g., Posts, Categories, Users)
      @posts = Post.where("title ILIKE ? OR body ILIKE ?", "%#{@query}%", "%#{@query}%")
      @categories = Category.where("name ILIKE ?", "%#{@query}%")
      @tags = Tag.where("name ILIKE ?", "%#{@query}%")
      @users = User.where("username ILIKE ?", "%#{@query}%")
    else
      @posts = []
      @categories = []
      @tags = []
      @users = []
    end
  end
end
