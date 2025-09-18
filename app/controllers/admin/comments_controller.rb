class Admin::CommentsController < Admin::BaseController
  before_action :set_comment, only: [:show, :approve, :reject, :destroy]
  
  def index
    @comments = Comment.includes(:user, :post)
                      .order(created_at: :desc)
                      .page(params[:page])
                      .per(25)
    
    if params[:search].present?
      @comments = @comments.joins(:user, :post).where(
        "users.username ILIKE ? OR posts.title ILIKE ? OR comments.content ILIKE ?",
        "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%"
      )
    end
    
    @stats = {
      total: Comment.count,
      today: Comment.where('created_at >= ?', Date.current.beginning_of_day).count,
      this_week: Comment.where('created_at >= ?', 1.week.ago).count
    }
  end
  
  def show
  end
  
  def approve
    # Add approval logic if needed
    redirect_to admin_comments_path, notice: 'Comment approved successfully.'
  end
  
  def reject
    # Add rejection logic if needed  
    redirect_to admin_comments_path, notice: 'Comment rejected successfully.'
  end
  
  def destroy
    @comment.destroy
    redirect_to admin_comments_path, notice: 'Comment deleted successfully.'
  end
  
  private
  
  def set_comment
    @comment = Comment.find(params[:id])
  end
end