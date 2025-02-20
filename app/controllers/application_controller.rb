class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_categories_and_tags

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :username, :avatar ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :username, :avatar ])
  end

  private

  def set_categories_and_tags
    @categories = Category.all
    @tags = Tag.all
  end
end
