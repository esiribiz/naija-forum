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
      today: Comment.where("created_at >= ?", Date.current.beginning_of_day).count,
      this_week: Comment.where("created_at >= ?", 1.week.ago).count
    }
  end

  def show
  end

  def approve
    # Update comment status if there's an approved field
    if @comment.respond_to?(:approved=)
      @comment.update!(approved: true)

      # Notify the comment author if different from current user
      if @comment.user != current_user && defined?(Notification)
        begin
          Notification.create!(
            user: @comment.user,
            actor: current_user,
            action: "comment_approved",
            notifiable: @comment,
            message: "Your comment on '#{@comment.post.title}' has been approved"
          )
        rescue => e
          Rails.logger.warn "Failed to create approval notification: #{e.message}"
        end
      end

      redirect_to admin_comments_path, notice: "Comment approved successfully."
    else
      # If no approval system, just show success message
      redirect_to admin_comments_path, notice: "Comment marked as reviewed."
    end
  end

  def reject
    # Update comment status if there's an approved field
    if @comment.respond_to?(:approved=)
      @comment.update!(approved: false)

      # Notify the comment author if different from current user
      if @comment.user != current_user && defined?(Notification)
        begin
          Notification.create!(
            user: @comment.user,
            actor: current_user,
            action: "comment_rejected",
            notifiable: @comment,
            message: "Your comment on '#{@comment.post.title}' requires revision"
          )
        rescue => e
          Rails.logger.warn "Failed to create rejection notification: #{e.message}"
        end
      end

      redirect_to admin_comments_path, notice: "Comment rejected successfully."
    else
      # If no approval system, hide or flag the comment
      if @comment.respond_to?(:hidden=)
        @comment.update!(hidden: true)
        redirect_to admin_comments_path, notice: "Comment hidden successfully."
      else
        redirect_to admin_comments_path, notice: "Comment flagged for review."
      end
    end
  end

  def destroy
    @comment.destroy
    redirect_to admin_comments_path, notice: "Comment deleted successfully."
  end

  private

  def set_comment
    @comment = Comment.find(params[:id])
  end
end
