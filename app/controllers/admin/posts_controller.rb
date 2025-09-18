class Admin::PostsController < Admin::BaseController
  before_action :set_post, only: [:show, :edit, :update, :destroy, :toggle_published]
  
  def index
    @posts = Post.includes(:user, :category, :comments)
                 .order(created_at: :desc)
                 .page(params[:page])
    
    # Apply filters if present
    @posts = @posts.where(published: params[:published]) if params[:published].present?
    @posts = @posts.where(category_id: params[:category_id]) if params[:category_id].present?
    @posts = @posts.joins(:user).where('users.username ILIKE ?', "%#{params[:search]}%") if params[:search].present?
    
    # Stats for the dashboard
    @total_posts = Post.count
    @published_posts = Post.where(published: true).count
    @draft_posts = Post.where(published: false).count
    @posts_today = Post.where('created_at >= ?', Date.current).count
    
    @categories = Category.all
  end
  
  def show
    @post_comments = @post.comments.includes(:user).order(created_at: :desc)
  end

  def edit
  end

  def update
    if @post.update(post_params)
      redirect_to admin_post_path(@post), notice: 'Post was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @post.destroy
    redirect_to admin_posts_path, notice: 'Post was successfully deleted.'
  end
  
  def toggle_published
    @post.update!(published: !@post.published)
    
    status = @post.published? ? 'published' : 'unpublished'
    
    # Send notification to post author if post was published by admin
    if @post.published? && @post.user != current_user
      Notification.notify(
        recipient: @post.user,
        actor: current_user,
        action: 'post_published',
        notifiable: @post
      )
    end
    
    redirect_to admin_posts_path, notice: "Post was successfully #{status}."
  end

  private
  
  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :body, :category_id, :published, :tag_list)
  end
  
end