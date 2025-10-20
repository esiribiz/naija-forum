class UsersController < ApplicationController
before_action :set_user, only: [ :show, :edit, :update ]
before_action :authenticate_user!

def show
authorize @user
# @user is already set from `set_user`
end

def edit
authorize @user
end

def update
authorize @user
if @user.update(user_params)
    redirect_to @user, notice: "Profile updated successfully."
else
    flash.now[:alert] = "Failed to update profile: #{@user.errors.full_messages.to_sentence}"
    render :edit, status: :unprocessable_entity
end
end

  private

  def set_user
    @user = User.friendly.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "User not found."
  end

  def user_params
    params.require(:user).permit(:name, :username, :email, :avatar, :bio, :location, :website, :twitter, :linkedin, :facebook, :first_name, :last_name)
  end

end
