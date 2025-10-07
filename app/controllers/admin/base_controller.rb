class Admin::BaseController < ApplicationController
  layout 'admin_sidebar'
  before_action :authenticate_user!
  before_action :ensure_admin_or_moderator
  after_action :cleanup_thread_locals
  
  # Skip Pundit verification for admin controllers since they have custom authorization logic
  skip_after_action :verify_policy_scoped, :verify_authorized
  
  protected
  
  def ensure_admin_or_moderator
    unless current_user&.staff?
      redirect_to root_path, alert: 'Access denied. Admin or moderator privileges required.'
    end
  end
  
  def ensure_admin
    unless current_user&.admin?
      redirect_to admin_root_path, alert: 'Access denied. Admin privileges required.'
    end
  end
  
  # Check if current user can modify user roles
  def can_manage_user_roles?
    current_user&.admin?
  end
  
  # Check if current user can create/delete categories and tags
  def can_manage_categories_and_tags?
    current_user&.admin?
  end
  
  # Check if current user can create new users
  def can_create_users?
    current_user&.admin?
  end
  
  # Check if current user can moderate content (posts, comments)
  def can_moderate_content?
    current_user&.staff?
  end
  
  # Helper method for views to check permissions
  def current_user_can?(action, resource = nil)
    case action
    when :manage_user_roles
      can_manage_user_roles?
    when :manage_categories_and_tags
      can_manage_categories_and_tags?
    when :create_users
      can_create_users?
    when :moderate_content
      can_moderate_content?
    when :edit_user_role
      # Only admins can change user roles, except their own
      current_user&.admin? && (resource.nil? || resource != current_user)
    else
      false
    end
  end
  
  helper_method :current_user_can?
  
  private
  
  # Clean up thread-local variables after each request
  def cleanup_thread_locals
    Thread.current[:current_admin_user] = nil
  end
end
