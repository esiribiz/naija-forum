class Admin::RoleManagementController < Admin::BaseController
  before_action :ensure_admin
  
  def index
    @users = User.includes(:posts, :comments)
                .order(:username)
                .page(params[:page])
                .per(25)
    
    if params[:search].present?
      @users = @users.where(
        "username ILIKE ? OR email ILIKE ? OR first_name ILIKE ? OR last_name ILIKE ?",
        "%#{params[:search]}%", "%#{params[:search]}%", 
        "%#{params[:search]}%", "%#{params[:search]}%"
      )
    end
    
    if params[:role].present? && User::VALID_ROLES.include?(params[:role])
      @users = @users.where(role: params[:role])
    end
    
    @role_counts = {
      admin: User.where(role: 'admin').count,
      moderator: User.where(role: 'moderator').count,
      user: User.where(role: 'user').count
    }
  end
  
  def update_role
    @user = User.find(params[:user_id])
    new_role = params[:role]
    
    unless User::VALID_ROLES.include?(new_role)
      render json: { error: 'Invalid role' }, status: :unprocessable_entity
      return
    end
    
    # Prevent demoting the last admin
    if @user.admin? && new_role != 'admin' && User.where(role: 'admin').count <= 1
      render json: { error: 'Cannot demote the last admin' }, status: :unprocessable_entity
      return
    end
    
    # Prevent users from changing their own role
    if @user == current_user
      render json: { error: 'You cannot change your own role' }, status: :unprocessable_entity
      return
    end
    
    old_role = @user.role
    
    # Set the current admin user for the email notification
    Thread.current[:current_admin_user] = current_user
    
    if @user.update(role: new_role)
      # Log the role change
      Rails.logger.info "Admin #{current_user.username} changed #{@user.username}'s role from #{old_role} to #{new_role}"
      
      # Send notification to the user about role change (this will trigger the email automatically via callback)
      create_role_change_notification(@user, old_role, new_role)
      
      render json: { 
        success: true, 
        message: "#{@user.username}'s role has been updated to #{new_role.capitalize}. A notification email will be sent.",
        new_role: new_role.capitalize,
        user_id: @user.id
      }
    else
      render json: { 
        error: "Failed to update role: #{@user.errors.full_messages.join(', ')}" 
      }, status: :unprocessable_entity
    end
  end
  
  private
  
  
  def create_role_change_notification(user, old_role, new_role)
    return unless defined?(Notification)
    
    Notification.create!(
      user: user,
      actor: current_user,
      action: 'role_changed',
      notifiable: user,
      message: "Your role has been changed from #{old_role.capitalize} to #{new_role.capitalize}"
    )
  rescue => e
    Rails.logger.error "Failed to create role change notification: #{e.message}"
  end
end