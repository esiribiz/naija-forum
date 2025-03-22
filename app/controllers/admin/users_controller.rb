class Admin::UsersController < ApplicationController
  layout 'admin'
  before_action :authenticate_user!
  before_action :verify_admin
  before_action :set_user, only: [:edit, :update]
  skip_after_action :verify_policy_scoped, only: :index
  # Option 2: Skip authorization check entirely (uncomment if using this approach instead of authorize calls)
  # skip_after_action :verify_authorized

  def index
    @users = User.all
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

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:role)
  end

  def verify_admin
    unless current_user&.admin?
      flash[:alert] = "You are not authorized to access this area."
      redirect_to root_path
    end
  end
end
