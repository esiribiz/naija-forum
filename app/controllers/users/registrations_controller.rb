# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]
  before_action :set_user_for_sidebar, only: [:edit, :update]

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  # def create
  #   super
  # end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  def update
    # Ensure @user is set before calling super
    @user = current_user
    super do |resource|
      # This block runs after the update attempt
      # Ensure @user is set to the resource for error handling
      @user = resource if resource.errors.any?
    end
  end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

  # Set @user for sidebar
  def set_user_for_sidebar
    @user = current_user
  end
  
  # Override to ensure @user is available in error scenarios
  def respond_with(resource, _opts = {})
    @user = resource if resource.is_a?(User)
    super
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    # Make security questions attributes optional but still permitted
    # This ensures users can update their profile without requiring security questions
    devise_parameter_sanitizer.permit(:account_update, keys: [
      :username, :avatar,
      { security_questions_attributes: [:id, :question, :answer, :_destroy] }
    ])
  end

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    user_path(resource)
  end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end

