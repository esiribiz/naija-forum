class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :toggle_admin]
  skip_after_action :verify_policy_scoped, only: :index
  # Option 2: Skip authorization check entirely (uncomment if using this approach instead of authorize calls)
  # skip_after_action :verify_authorized

  def index
    @users = User.includes(:posts, :comments).order(created_at: :desc).page(params[:page])
    
    # Apply filters if present
    @users = @users.where(role: params[:role]) if params[:role].present?
    @users = @users.where('username ILIKE ?', "%#{params[:search]}%") if params[:search].present?
    
    # Stats for the dashboard
    @total_users = User.count
    @admin_users = User.where(role: 'admin').count
    @new_users_today = User.where('created_at >= ?', Date.current).count
  end
  
  def show
    @user = User.find(params[:id])
    authorize @user
    @user_posts = @user.posts.includes(:category).order(created_at: :desc).limit(10)
    @user_comments = @user.comments.includes(:post).order(created_at: :desc).limit(10)
  end

  def edit
    # The user is already set by the before_action
    authorize @user
  end

  def update
    authorize @user
    if @user.update(user_params)
      redirect_to admin_users_path, notice: "User was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    authorize @user
    if @user == current_user
      redirect_to admin_users_path, alert: 'You cannot delete yourself.'
      return
    end
    
    @user.destroy
    redirect_to admin_users_path, notice: 'User was successfully deleted.'
  end
  
  def toggle_admin
    authorize @user
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
