class PostsController < ApplicationController
  include HtmlProcessor
  protect_from_forgery with: :exception
  before_action :authenticate_user!, except: %i[index show]
  before_action :set_security_headers
  before_action :validate_request_format
  before_action :set_post, only: %i[show edit update destroy]
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActionController::InvalidAuthenticityToken, with: :invalid_auth_token

  # GET /posts or /posts.json
def index
@categories = Category.all

if params[:category_id]
    @category = Category.find(params[:category_id])
    @posts = policy_scope(@category.posts)
    .includes(:user, :category)
    .order(created_at: :desc)
    .page(params[:page])
    .per(10)
    else
    @posts = policy_scope(Post)
        .includes(:user, :category)
        .order(created_at: :desc)
        .page(params[:page])
        .per(10)
    end
  end

  # GET /posts/1 or /posts/1.json
def show
authorize @post
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
assign_tags(@post)

    respond_to do |format|
      if @post.save
        format.html { redirect_to @post, notice: "Post was successfully created." }
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
assign_tags(@post)

    respond_to do |format|
      if @post.update(post_params)
        format.html { redirect_to @post, notice: "Post was successfully updated." }
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

private

# Finds the post before performing actions
def set_post
@post = Post.includes(:user, :category).find(params[:id])
rescue ActiveRecord::RecordNotFound
raise ActiveRecord::RecordNotFound, "Post not found"
end

def set_security_headers
response.headers['Content-Security-Policy'] = "default-src 'self'; img-src 'self' https:; script-src 'self'; style-src 'self' 'unsafe-inline'"
response.headers['X-Frame-Options'] = 'SAMEORIGIN'
response.headers['X-XSS-Protection'] = '1; mode=block'
response.headers['X-Content-Type-Options'] = 'nosniff'
response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
response.headers['Permissions-Policy'] = 'geolocation=(), microphone=()'
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
    format.html { render file: Rails.public_path.join('404.html'), status: :not_found }
    format.json { render json: { error: 'Resource not found' }, status: :not_found }
end
end

def user_not_authorized
respond_to do |format|
    format.html { redirect_to root_path, alert: 'You are not authorized to perform this action.' }
    format.json { render json: { error: 'Unauthorized' }, status: :forbidden }
end
end

def invalid_auth_token
respond_to do |format|
    format.html { redirect_to new_user_session_path, alert: 'Your session has expired. Please sign in again.' }
    format.json { render json: { error: 'Invalid authenticity token' }, status: :unprocessable_entity }
end
end

  # Assign tags to the post
  def assign_tags(post)
    if params[:post][:tag_list].present?
      tag_names = params[:post][:tag_list].split(",").map(&:strip)
      post.tags = tag_names.map { |name| Tag.find_or_create_by(name: name) }
    end
  end
end
