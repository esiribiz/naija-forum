class SearchController < ApplicationController
  def index
    @query = params[:query]

    if @query.present?
      # Searching across multiple models with policy scopes for authorization
      @posts = policy_scope(Post).where("title ILIKE ? OR body ILIKE ?", "%#{@query}%", "%#{@query}%")
      @categories = policy_scope(Category).where("name ILIKE ?", "%#{@query}%")
      @tags = policy_scope(Tag).where("name ILIKE ?", "%#{@query}%")
      @users = policy_scope(User).where("username ILIKE ?", "%#{@query}%")
    else
      @posts = []
      @categories = []
      @tags = []
      @users = []
    end
  end
end
