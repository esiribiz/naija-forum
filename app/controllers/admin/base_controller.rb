class Admin::BaseController < ApplicationController
  layout "admin_sidebar"
  before_action :authenticate_user!
  before_action :ensure_admin_or_moderator
  before_action :validate_admin_session
  before_action :enforce_admin_security_headers
  after_action :cleanup_thread_locals

  # Skip Pundit verification for admin controllers since they have custom authorization logic
  skip_after_action :verify_policy_scoped, :verify_authorized

  # Error handling for admin interface
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::RoutingError, with: :routing_error
  rescue_from ActionController::MissingExactTemplate, with: :template_not_found
  rescue_from SecurityError, with: :handle_admin_security_violation

  protected

  def ensure_admin_or_moderator
    unless current_user&.staff?
      redirect_to root_path, alert: "Access denied. Admin or moderator privileges required."
    end
  end

  def ensure_admin
    unless current_user&.admin?
      redirect_to admin_root_path, alert: "Access denied. Admin privileges required."
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

  # Error handling methods
  def record_not_found(exception)
    Rails.logger.error "Admin record not found: #{exception.message}"
    redirect_to admin_root_path, alert: "Record not found. It may have been deleted or you may not have permission to access it."
  end

  def routing_error(exception)
    Rails.logger.error "Admin routing error: #{exception.message}"
    redirect_to admin_root_path, alert: "Page not found. The URL may be incorrect or the feature may not be available."
  end

  def template_not_found(exception)
    Rails.logger.error "Admin template not found: #{exception.message}"
    redirect_to admin_root_path, alert: "This page is not available yet. Please contact support if this persists."
  end

  # SECURITY: Validate admin session integrity and timeout
  def validate_admin_session
    # Check admin session timeout (shorter than regular users)
    if session[:admin_last_activity].present?
      admin_timeout = Rails.env.production? ? 30.minutes : 2.hours
      if Time.current - session[:admin_last_activity].to_time > admin_timeout
        Rails.logger.warn "SECURITY: Admin session expired for user #{current_user&.id}"
        reset_session
        redirect_to new_user_session_path, alert: "Admin session has expired. Please log in again."
        return
      end
    end

    # Update last activity timestamp
    session[:admin_last_activity] = Time.current

    # Validate admin user still has privileges
    unless current_user&.staff?
      Rails.logger.error "SECURITY: User #{current_user&.id} lost admin privileges during session"
      reset_session
      redirect_to root_path, alert: "Admin privileges have been revoked. Please contact support."
    end
  end

  # SECURITY: Enhanced security headers for admin interface
  def enforce_admin_security_headers
    return if Rails.env.development?

    # Enhanced CSP for admin interface
    response.headers["Content-Security-Policy"] = "default-src 'self'; script-src 'self' 'unsafe-eval' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self';"

    # Additional security headers for admin
    response.headers["X-Admin-Interface"] = "true"
    response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, private"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"

    # Prevent admin pages from being embedded in frames
    response.headers["X-Frame-Options"] = "DENY"
  end

  # SECURITY: Handle security violations in admin interface
  def handle_admin_security_violation(exception)
    Rails.logger.error "SECURITY VIOLATION in admin interface: #{exception.message} - User: #{current_user&.id}, IP: #{request.remote_ip}"

    # Log detailed security event
    log_admin_security_event("Security violation: #{exception.message}", severity: :error)

    # Reset session on security violations
    reset_session

    redirect_to new_user_session_path, alert: "Security violation detected. Please log in again."
  end

  # SECURITY: Log admin-specific security events
  def log_admin_security_event(message, severity: :info)
    Rails.logger.tagged("ADMIN_SECURITY") do
      context = {
        user_id: current_user&.id,
        username: current_user&.username,
        role: current_user&.role,
        ip: request.remote_ip,
        path: request.fullpath,
        user_agent: request.user_agent,
        timestamp: Time.current,
        session_id: session.id
      }

      Rails.logger.public_send(severity, "#{message} | #{context.to_json}")
    end
  end
end
