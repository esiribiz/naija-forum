class Admin::PostsController < Admin::BaseController
  before_action :set_post, only: [:show, :edit, :update, :destroy, :toggle_published]

  def index
    @posts = Post.includes(:user, :category, :comments)

    # Apply filters if present
    @posts = @posts.where(published: params[:published] == "true") if params[:published].present?
    @posts = @posts.where(category_id: params[:category_id]) if params[:category_id].present?

    # Search functionality
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @posts = @posts.joins(:user).where(
        "posts.title ILIKE ? OR posts.body ILIKE ? OR users.username ILIKE ?",
        search_term, search_term, search_term
      )
    end

    # Date range filter
    case params[:date_range]
    when "today"
      @posts = @posts.where("posts.created_at >= ?", Date.current.beginning_of_day)
    when "week"
      @posts = @posts.where("posts.created_at >= ?", 1.week.ago)
    when "month"
      @posts = @posts.where("posts.created_at >= ?", 1.month.ago)
    when "3months"
      @posts = @posts.where("posts.created_at >= ?", 3.months.ago)
    when "year"
      @posts = @posts.where("posts.created_at >= ?", 1.year.ago)
    end

    # Sorting
    case params[:sort]
    when "oldest"
      @posts = @posts.order(created_at: :asc)
    when "most_comments"
      @posts = @posts.left_joins(:comments).group("posts.id").order("COUNT(comments.id) DESC")
    when "recent_activity"
      @posts = @posts.order(updated_at: :desc)
    when "alpha_asc"
      @posts = @posts.order(:title)
    when "alpha_desc"
      @posts = @posts.order(title: :desc)
    else # 'newest' or default
      @posts = @posts.order(created_at: :desc)
    end

    # Apply pagination
    @posts = @posts.page(params[:page]).per(25)

    # Stats for the dashboard
    @total_posts = Post.count
    @published_posts = Post.where(published: true).count
    @draft_posts = Post.where(published: false).count
    @posts_today = Post.where("created_at >= ?", Date.current.beginning_of_day).count

    @categories = Category.all
  end

  def show
    @post_comments = @post.comments.includes(:user).order(created_at: :desc)
  end

  def new
    @post = Post.new
    @categories = Category.all
  end

  def create
    @post = current_user.posts.build(post_params)

    if @post.save
      redirect_to admin_post_path(@post), notice: "Post was successfully created."
    else
      @categories = Category.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @categories = Category.all
  end

  def update
    if @post.update(post_params)
      redirect_to admin_post_path(@post), notice: "Post was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to admin_posts_path, notice: "Post was successfully deleted."
  end

  def toggle_published
    # Ensure this is only accessed via PATCH method
    unless request.patch?
      redirect_to admin_post_path(@post), alert: "Invalid request method. Use the toggle button instead."
      return
    end

    @post.update!(published: !@post.published)

    status = @post.published? ? "published" : "unpublished"

    # Send notification to post author if post was published by admin
    if @post.published? && @post.user != current_user
      Notification.notify(
        recipient: @post.user,
        actor: current_user,
        action: "post_published",
        notifiable: @post
      )
    end

    redirect_to admin_post_path(@post), notice: "Post was successfully #{status}."
  end

  private

  def set_post
    # Admin interface uses numeric IDs for consistency and security
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :body, :category_id, :published, :tag_list)
  end

end
