class ApplicationController < ActionController::Base
include Pundit::Authorization
include SecurityEnforceable

# Security Configuration
protect_from_forgery with: :exception, prepend: true
before_action :verify_session_security
before_action :track_user_activity

# Authentication & Setup
before_action :authenticate_user!
before_action :configure_permitted_parameters, if: :devise_controller?
before_action :set_categories_and_tags

# Log security events
after_action :log_user_activity, if: :user_signed_in?

# Pundit authorization
after_action :verify_policy_scoped, only: :index
after_action :verify_authorized, except: :index
skip_after_action :verify_policy_scoped, :verify_authorized, if: :devise_controller?

# Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
allow_browser versions: :modern

rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def configure_permitted_parameters
    # Ensure extra fields persist on invalid sign up without wiping user input
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :username, :first_name, :last_name, :avatar ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :username, :first_name, :last_name, :avatar ])
  end

private

def ensure_rules_accepted
  if user_signed_in? && current_user.accepted_rules_at.blank? && !on_rules_page?
    redirect_to rules_path, alert: "Please read and accept the community rules to continue."
  end
end

def on_rules_page?
  controller_name == "pages" && action_name.in?(%w[rules accept_rules])
end

def set_categories_and_tags
    @categories = Category.all
    @tags = Tag.all
end

def user_not_authorized
    # Security event logging is now handled by SecurityEnforceable concern
    log_security_event("Unauthorized access attempt", severity: :warn)
    flash[:alert] = "You are not authorized to perform this action."
    redirect_back(fallback_location: root_path)
end

  def verify_session_security
    # Skip all session security checks in development and test environments
    return if Rails.env.development? || Rails.env.test?

    if session_expired? || suspicious_activity_detected?
      reset_session
      redirect_to new_user_session_path, alert: "Your session has expired. Please log in again."
    end
  end

  def track_user_activity
    return unless user_signed_in?

    current_user.track_activity(request.remote_ip)

    # Update last_active_at for online status tracking
    current_user.update_column(:last_active_at, Time.current) if current_user.last_active_at.nil? || current_user.last_active_at < 1.minute.ago

    session[:last_activity] = Time.current
  end

  def log_user_activity
    Rails.logger.info(
      "User activity: user_id=#{current_user.id} " \
      "action=#{action_name} " \
      "controller=#{controller_name} " \
      "ip=#{request.remote_ip} " \
      "user_agent=#{request.user_agent}"
    )
  end

  def session_expired?
    return false unless user_signed_in?

    last_activity = session[:last_activity]
    return true if last_activity.nil?

    Time.current - last_activity.to_time > SecurityConfig.session_timeout
  end

  def suspicious_activity_detected?
    return false unless user_signed_in?

    current_user.suspicious_activity?
  end
end
