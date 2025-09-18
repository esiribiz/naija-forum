class Admin::BaseController < ApplicationController
  layout 'admin_sidebar'
  before_action :authenticate_user!
  before_action :ensure_admin_or_moderator
  
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
end