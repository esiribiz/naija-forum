class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :toggle_admin, :toggle_suspend]

  def index
    @users = User.includes(:posts, :comments)
    
    # Apply role filter
    @users = @users.where(role: params[:role]) if params[:role].present?
    
    # Apply search filter
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @users = @users.where('username ILIKE ? OR email ILIKE ? OR first_name ILIKE ? OR last_name ILIKE ?', 
                           search_term, search_term, search_term, search_term)
    end
    
    # Apply activity filter
    case params[:activity]
    when 'online'
      @users = @users.online
    when 'recent'
      @users = @users.recently_active
    when 'inactive'
      @users = @users.inactive
    when 'never'
      @users = @users.never_logged_in
    end
    
    # Apply joined period filter
    case params[:joined]
    when 'today'
      @users = @users.joined_today
    when 'week'
      @users = @users.joined_this_week
    when 'month'
      @users = @users.joined_this_month
    when '3months'
      @users = @users.joined_last_3_months
    when 'year'
      @users = @users.joined_this_year
    end
    
    # Apply minimum posts filter
    if params[:min_posts].present? && params[:min_posts].to_i > 0
      @users = @users.left_joins(:posts).group('users.id').having('COUNT(posts.id) >= ?', params[:min_posts].to_i)
    end
    
    # Apply minimum comments filter
    if params[:min_comments].present? && params[:min_comments].to_i > 0
      @users = @users.left_joins(:comments).group('users.id').having('COUNT(comments.id) >= ?', params[:min_comments].to_i)
    end
    
    # Apply sorting
    case params[:sort]
    when 'oldest'
      @users = @users.order(created_at: :asc)
    when 'most_active'
      @users = @users.most_active
    when 'most_posts'
      @users = @users.by_posts_count
    when 'most_comments'
      @users = @users.by_comments_count
    when 'alpha_asc'
      @users = @users.order(:username)
    when 'alpha_desc'
      @users = @users.order(username: :desc)
    else # 'newest' or default
      @users = @users.order(created_at: :desc)
    end
    
    # Apply pagination
    per_page = params[:per_page].present? ? params[:per_page].to_i : 25
    per_page = [per_page, 100].min # Max 100 per page
    @users = @users.page(params[:page]).per(per_page) if @users.respond_to?(:page)
    
    # Stats for the dashboard
    @total_users = User.count
    @admin_users = User.where(role: 'admin').count
    @users_today = User.joined_today.count
    @moderator_users = User.where(role: 'moderator').count
    @new_users_this_week = User.joined_this_week.count
    @online_users = User.online.count
    @recent_users = User.recently_active.count
    @inactive_users = User.inactive.count
    @never_logged_in_users = User.never_logged_in.count
  end
  
  def show
    # Admin access is already validated by Admin::BaseController
    @user_posts = @user.posts.includes(:category).order(created_at: :desc).limit(10)
    @user_comments = @user.comments.includes(:post).order(created_at: :desc).limit(10)
  end

  def edit
    # Admin access is already validated by Admin::BaseController
  end

  def update
    # Admin access is already validated by Admin::BaseController
    if @user.update(user_params)
      redirect_to admin_users_path, notice: "User was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    # Admin access is already validated by Admin::BaseController
    if @user == current_user
      redirect_to admin_users_path, alert: 'You cannot delete yourself.'
      return
    end
    
    @user.destroy
    redirect_to admin_users_path, notice: 'User was successfully deleted.'
  end

    # toggle_suspend
  def toggle_suspend
    if @user == current_user
      redirect_to admin_users_path, alert: "You cannot suspend yourself."
      return
    end

    @user.update!(suspended: !@user.suspended)
    action = @user.suspended? ? "suspended" : "unsuspended"
    redirect_to admin_user_path(@user), notice: "User has been #{action}."
  end

  
  def toggle_admin
    # Admin access is already validated by Admin::BaseController
    if @user == current_user
      redirect_to admin_users_path, alert: 'You cannot change your own admin status.'
      return
    end
    
    new_role = @user.admin? ? 'user' : 'admin'
    @user.update!(role: new_role)
    
    action = @user.admin? ? 'granted' : 'removed'
    redirect_to admin_users_path, notice: "Admin privileges #{action} for #{@user.username}."  
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    # Allow more user fields for editing
    permitted_params = params.require(:user).permit(:username, :email, :first_name, :last_name, :role, :bio)
    
    # Additional security: validate role value
    if permitted_params[:role].present?
      unless User::VALID_ROLES.include?(permitted_params[:role])
        raise ActionController::ParameterMissing.new("Invalid role specified")
      end
    end
    
    permitted_params
  end

end
