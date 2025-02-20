class UsersController < ApplicationController
  before_action :set_user, only: [ :show, :edit, :update ]
  before_action :authenticate_user!
  before_action :authorize_user, only: [ :edit, :update ]

  def show
    # @user is already set from `set_user`
  end

  def edit
    # Only the owner can access this due to `authorize_user`
  end

  def update
    if @user.update(user_params)
      redirect_to @user, notice: "Profile updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def authorize_user
    redirect_to @user, alert: "You are not authorized to edit this profile." unless current_user == @user
  end

  def user_params
    params.require(:user).permit(:name, :username, :email, :avatar, :bio, :location, :website, :twitter, :linkedin, :facebook)
  end
end
