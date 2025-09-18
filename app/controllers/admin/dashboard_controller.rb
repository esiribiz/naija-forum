class Admin::DashboardController < Admin::BaseController
  
  def index
    # Cache frequently accessed dates
    today = Date.current.beginning_of_day
    week_ago = 1.week.ago.beginning_of_day
    
    # Use Rails.cache for expensive calculations if needed
    @stats = {
      users: {
        total: User.count,
        new_today: User.where('created_at >= ?', today).count,
        new_this_week: User.where('created_at >= ?', week_ago).count,
        active_today: User.where('last_active_at >= ?', today).count,
        admins: User.where(role: 'admin').count
      },
      posts: {
        total: Post.count,
        published: Post.where(published: true).count,
        draft: Post.where(published: false).count,
        new_today: Post.where('created_at >= ?', today).count,
        new_this_week: Post.where('created_at >= ?', week_ago).count
      },
      comments: {
        total: Comment.count,
        new_today: Comment.where('created_at >= ?', today).count,
        new_this_week: Comment.where('created_at >= ?', week_ago).count
      },
      categories: {
        total: Category.count,
        with_posts: Category.joins(:posts).distinct.count
      },
      notifications: {
        total: Notification.count,
        unread: Notification.where(read: false).count,
        sent_today: Notification.where('created_at >= ?', today).count
      }
    }
    
    # Recent activity
    @recent_users = User.order(created_at: :desc).limit(5)
    @recent_posts = Post.includes(:user, :category).order(created_at: :desc).limit(5)
    @recent_comments = Comment.includes(:user, :post).order(created_at: :desc).limit(5)
    
    # Charts data
    @user_growth_data = user_growth_data
    @post_activity_data = post_activity_data
    @comment_activity_data = comment_activity_data
  end
  
  private
  
  def ensure_admin
    redirect_to root_path, alert: 'Access denied.' unless current_user&.admin?
  end
  
  def user_growth_data
    # Last 30 days user registration data - optimized with single query
    start_date = 29.days.ago.to_date
    end_date = Date.current
    
    # Single database query to get all counts
    counts_by_date = User.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
                        .group("DATE(created_at)")
                        .count
    
    # Generate data for all dates, filling in zeros where needed
    (start_date..end_date).map do |date|
      {
        date: date.strftime('%m/%d'),
        count: counts_by_date[date.to_s] || 0
      }
    end
  end
  
  def post_activity_data
    # Last 30 days post creation data - optimized with single query
    start_date = 29.days.ago.to_date
    end_date = Date.current
    
    # Single database query to get all counts
    counts_by_date = Post.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
                        .group("DATE(created_at)")
                        .count
    
    # Generate data for all dates, filling in zeros where needed
    (start_date..end_date).map do |date|
      {
        date: date.strftime('%m/%d'),
        count: counts_by_date[date.to_s] || 0
      }
    end
  end
  
  def comment_activity_data
    # Last 30 days comment creation data - optimized with single query
    start_date = 29.days.ago.to_date
    end_date = Date.current
    
    # Single database query to get all counts
    counts_by_date = Comment.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
                           .group("DATE(created_at)")
                           .count
    
    # Generate data for all dates, filling in zeros where needed
    (start_date..end_date).map do |date|
      {
        date: date.strftime('%m/%d'),
        count: counts_by_date[date.to_s] || 0
      }
    end
  end
end