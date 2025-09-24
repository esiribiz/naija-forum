class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :toggle_admin, :toggle_suspend]

  def index
    @users = User.includes(:posts, :comments).order(created_at: :desc)
    
    # Apply filters if present
    @users = @users.where(role: params[:role]) if params[:role].present?
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @users = @users.where('username ILIKE ? OR email ILIKE ? OR first_name ILIKE ? OR last_name ILIKE ?', 
                           search_term, search_term, search_term, search_term)
    end
    
    # Add pagination if kaminari is available
    @users = @users.page(params[:page]).per(20) if @users.respond_to?(:page)
    
    # Stats for the dashboard
    @total_users = User.count
    @admin_users = User.where(role: 'admin').count
    @users_today = User.where('created_at >= ?', Date.current).count
    @moderator_users = User.where(role: 'moderator').count
    @new_users_this_week = User.where('created_at >= ?', 1.week.ago).count
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
