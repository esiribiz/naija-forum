class PostsController < ApplicationController
  include HtmlProcessor
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :ensure_rules_accepted, if: :user_signed_in?
  skip_after_action :verify_authorized, only: [:latest, :popular]
  before_action :set_security_headers
  before_action :validate_request_format
  before_action :set_post, only: %i[show edit update destroy]
  before_action :set_user_for_sidebar, only: %i[new create edit update]
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActionController::InvalidAuthenticityToken, with: :invalid_auth_token

  # GET /posts or /posts.json
def index
@categories = Category.all

# Only authenticated users can access posts listing
if params[:tag_id]
    @tag = Tag.find(params[:tag_id])
    @posts = policy_scope(Post)
      .joins(:post_tags)
      .where(post_tags: { tag_id: @tag.id })
      .includes(:user, :category, :tags)
      .order(created_at: :desc)
      .page(params[:page])
      .per(20)
elsif params[:tag_category]
    @tag_category = params[:tag_category]
    @posts = policy_scope(Post)
      .joins(:post_tags, :tags)
      .where(tags: { category: @tag_category })
      .includes(:user, :category, :tags)
      .order(created_at: :desc)
      .page(params[:page])
      .per(20)
      .distinct
elsif params[:category_id]
    @category = Category.find(params[:category_id])
    @posts = policy_scope(@category.posts)
    .includes(:user, :category)
    .order(created_at: :desc)
    .page(params[:page])
    .per(20)
elsif params[:user]
    @user = User.find(params[:user])
    @posts = policy_scope(@user.posts)
        .includes(:user, :category)
        .order(created_at: :desc)
        .page(params[:page])
        .per(20)
else
    @posts = policy_scope(Post)
        .includes(:user, :category)
        .order(created_at: :desc)
        .page(params[:page])
        .per(20)
end
end

  # GET /posts/1 or /posts/1.json
def show
  authorize @post
  # Fetch related posts from the same category
  @related_posts = Post.where(category_id: @post.category_id)
                      .where.not(id: @post.id)
                      .includes(:user, :category)
                      .order(created_at: :desc)
                      .limit(5)
end

  # GET /posts/new
def new
@post = Post.new
authorize @post
end

  # GET /posts/1/edit
def edit
authorize @post
end

  # POST /posts or /posts.json
def create
@post = current_user.posts.build(post_params)
authorize @post
@post.user_for_suggestions = current_user  # Set user for tag suggestions

    respond_to do |format|
      if @post.save
        handle_tag_suggestions(@post)
        format.html { redirect_to @post, notice: post_creation_notice(@post) }
        format.json { render :show, status: :created, location: @post }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /posts/1 or /posts/1.json
def update
authorize @post
@post.user_for_suggestions = current_user  # Set user for tag suggestions

    respond_to do |format|
      if @post.update(post_params)
        handle_tag_suggestions(@post)
        format.html { redirect_to @post, notice: post_update_notice(@post) }
        format.json { render :show, status: :ok, location: @post }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/1 or /posts/1.json
def destroy
authorize @post
@post.destroy!
    respond_to do |format|
      format.html { redirect_to posts_path, status: :see_other, notice: "Post was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  # GET /latest - Shows latest posts (chronological order)
  def latest
    @categories = Category.all

    @posts = policy_scope(Post)
      .includes(:user, :category)
      .order(created_at: :desc)
      .page(params[:page])
      .per(20)
  end

  # GET /popular - Shows popular posts (by comment count and recent activity)
  def popular
    @categories = Category.all

    @posts = policy_scope(Post)
      .includes(:user, :category, :comments)
      .left_joins(:comments)
      .group("posts.id")
      .order("COUNT(comments.id) DESC, posts.created_at DESC")
      .page(params[:page])
      .per(20)
  end

private

# Set @user for sidebar in user-focused pages
def set_user_for_sidebar
  @user = current_user if user_signed_in?
end

# Finds the post before performing actions
def set_post
@post = Post.includes(
  :user,
  :category,
  comments: [
    :user,
    { replies: :user }
  ]
).find(params[:id])
rescue ActiveRecord::RecordNotFound
raise ActiveRecord::RecordNotFound, "Post not found"
end

def set_security_headers
  # CSP is now handled by Rails configuration in config/initializers/content_security_policy.rb
  response.headers["X-Frame-Options"] = "SAMEORIGIN"
  response.headers["X-XSS-Protection"] = "1; mode=block"
  response.headers["X-Content-Type-Options"] = "nosniff"
  response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
  response.headers["Permissions-Policy"] = "geolocation=(), microphone=()"
end

# Strong parameters with sanitization
def post_params
sanitized_params = params.require(:post).permit(:title, :body, :category_id, :tag_list, images: [])
sanitized_params[:title] = sanitize_title(sanitized_params[:title])
sanitized_params[:body] = sanitize_content(sanitized_params[:body])
sanitized_params
end

def sanitize_title(title)
return if title.blank?
ActionController::Base.helpers.sanitize(title, tags: [], attributes: [])
end

def sanitize_content(content)
  return if content.blank?
  process_html(content)
end

def validate_request_format
return if request.format.html? || request.format.json?
head :not_acceptable
end

def not_found
respond_to do |format|
    format.html { render file: Rails.public_path.join("404.html"), status: :not_found }
    format.json { render json: { error: "Resource not found" }, status: :not_found }
end
end

def user_not_authorized
respond_to do |format|
    format.html { redirect_to root_path, alert: "You are not authorized to perform this action." }
    format.json { render json: { error: "Unauthorized" }, status: :forbidden }
end
end

def invalid_auth_token
respond_to do |format|
    format.html { redirect_to new_user_session_path, alert: "Your session has expired. Please sign in again." }
    format.json { render json: { error: "Invalid authenticity token" }, status: :unprocessable_entity }
end
end

  # Handle tag suggestions after post save
  def handle_tag_suggestions(post)
    return unless post.unapproved_tags&.any?

    flash[:info] = "Some tags were not recognized and have been submitted for review: #{post.unapproved_tags.map(&:name).join(', ')}"
  end

  # Generate appropriate success notice based on tag suggestions
  def post_creation_notice(post)
    if post.unapproved_tags&.any?
      "Post was successfully created! Some tags are pending approval."
    else
      "Post was successfully created."
    end
  end

  def post_update_notice(post)
    if post.unapproved_tags&.any?
      "Post was successfully updated! Some tags are pending approval."
    else
      "Post was successfully updated."
    end
  end
end
