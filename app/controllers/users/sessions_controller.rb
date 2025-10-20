# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  before_action :check_location_restrictions, only: [:create]
  before_action :check_suspicious_activity, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  def create
    # Create a login activity record for analysis
    LoginActivity.create(
      user: User.find_by(email: params[:user][:email]),
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      login_at: Time.current,
      success: false # Default to false, will be updated to true on successful login
    )

    # Continue with default Devise login action
    super do |user|
      if user.persisted? && user.valid_for_authentication?
        # Update the login activity to show success
        activity = user.login_activities.order(created_at: :desc).first
        activity.update(success: true) if activity
      end
    end
  end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  protected

  # Redirect to user dashboard after successful sign in
  def after_sign_in_path_for(resource)
    user_path(resource)
  end

  def check_location_restrictions
    # Skip for non-production environments for easier development/testing
    return unless Rails.env.production?

    # Get geolocation data for the current IP
    ip_data = IpGeolocationService.lookup(request.remote_ip)

    if ip_data.present? && restricted_region?(ip_data)
      flash[:alert] = "Login from your region is not permitted for security reasons."
      redirect_to new_user_session_path
      return false
    end
  end

  def check_suspicious_activity
    return unless user_exists?

    user = User.find_by(email: params[:user][:email])

    if user && user.suspicious_activity?(request.remote_ip)
      security_alert = "Suspicious activity detected with your account. Please contact support."
      flash[:alert] = security_alert

      # Log the suspicious activity
      Rails.logger.warn("SECURITY ALERT: Suspicious login attempt for user #{user.email} from IP #{request.remote_ip}")

      redirect_to new_user_session_path
      return false
    end
  end

  def restricted_region?(ip_data)
    # List of restricted countries (African countries)
    restricted_countries = [
      "Algeria", "Angola", "Benin", "Botswana", "Burkina Faso", "Burundi",
      "Cabo Verde", "Cameroon", "Central African Republic", "Chad", "Comoros",
      "Congo", "Democratic Republic of the Congo", "Djibouti", "Egypt",
      "Equatorial Guinea", "Eritrea", "Eswatini", "Ethiopia", "Gabon", "Gambia",
      "Ghana", "Guinea", "Guinea-Bissau", "Ivory Coast", "Kenya", "Lesotho",
      "Liberia", "Libya", "Madagascar", "Malawi", "Mali", "Mauritania", "Mauritius",
      "Morocco", "Mozambique", "Namibia", "Niger", "Nigeria", "Rwanda",
      "Sao Tome and Principe", "Senegal", "Seychelles", "Sierra Leone", "Somalia",
      "South Africa", "South Sudan", "Sudan", "Tanzania", "Togo", "Tunisia",
      "Uganda", "Zambia", "Zimbabwe"
    ]

    # Check if the country is in the restricted list
    restricted_countries.include?(ip_data[:country]) ||
      (ip_data[:continent].present? && ip_data[:continent].downcase == "africa")
  end

  def user_exists?
    params[:user] && params[:user][:email].present? &&
      User.exists?(email: params[:user][:email])
  end
end
