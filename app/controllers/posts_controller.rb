class PostsController < ApplicationController
  before_action :authenticate_user!, except: %i[index show]
  before_action :set_post, only: %i[show edit update destroy]
  before_action :authorize_user, only: %i[edit update destroy]

  # GET /posts or /posts.json
  def index
    @categories = Category.all

    if params[:category_id]
      @category = Category.find(params[:category_id])
      @posts = @category.posts.includes(:user, :category).order(created_at: :desc)
    else
      # Ensure users can only see their own posts
      if user_signed_in?
        @posts = Post.includes(:user, :category).order(created_at: :desc)
      end
    end
  end

  # GET /posts/1 or /posts/1.json
  def show
    # Ensure users can only see their own posts
    if @post.user != current_user && !user_signed_in?
      redirect_to posts_path, alert: "You can only view your own posts."
    end
  end

  # GET /posts/new
  def new
    @post = Post.new
  end

  # GET /posts/1/edit
  def edit
    # Only allow the post owner to edit
  end

  # POST /posts or /posts.json
  def create
    @post = current_user.posts.build(post_params)
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
    @post.destroy!
    respond_to do |format|
      format.html { redirect_to posts_path, status: :see_other, notice: "Post was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Finds the post before performing actions
  def set_post
    @post = Post.find(params[:id])
  end

  # Ensures only the post owner can edit/update/delete
  def authorize_user
    unless @post.user == current_user || current_user.role == "admin"
      redirect_to posts_path, alert: "You are not authorized to modify this post."
    end
  end

  # Strong parameters
  def post_params
    params.require(:post).permit(:title, :body, :category_id, :tag_list, images: [])
  end

  # Assign tags to the post
  def assign_tags(post)
    if params[:post][:tag_list].present?
      tag_names = params[:post][:tag_list].split(",").map(&:strip)
      post.tags = tag_names.map { |name| Tag.find_or_create_by(name: name) }
    end
  end
end
