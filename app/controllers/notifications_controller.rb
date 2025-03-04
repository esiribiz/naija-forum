# frozen_string_literal: true

class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notification, only: [:mark_as_read, :destroy]

  # GET /notifications
  def index
    @notifications = current_user.notifications
                                .includes(:actor, :notifiable)
                                .order(created_at: :desc)
                                .page(params[:page])
                                .per(10)
    
    respond_to do |format|
      format.html
      format.json { render json: @notifications }
    end
  end

  # PATCH /notifications/:id/mark_as_read
  def mark_as_read
    if @notification.update(read_at: Time.current)
      respond_to do |format|
        format.html { redirect_to notifications_path, notice: "Notification marked as read." }
        format.json { render json: @notification }
      end
    else
      respond_to do |format|
        format.html { redirect_to notifications_path, alert: "Could not mark notification as read." }
        format.json { render json: @notification.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH /notifications/mark_all_as_read
  def mark_all_as_read
    if current_user.notifications.unread.update_all(read_at: Time.current)
      respond_to do |format|
        format.html { redirect_to notifications_path, notice: "All notifications marked as read." }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to notifications_path, alert: "Could not mark all notifications as read." }
        format.json { head :unprocessable_entity }
      end
    end
  end

  # DELETE /notifications/:id
  def destroy
    if @notification.destroy
      respond_to do |format|
        format.html { redirect_to notifications_path, notice: "Notification deleted." }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to notifications_path, alert: "Could not delete notification." }
        format.json { render json: @notification.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /notifications/clear
  def clear
    if current_user.notifications.destroy_all
      respond_to do |format|
        format.html { redirect_to notifications_path, notice: "All notifications cleared." }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to notifications_path, alert: "Could not clear notifications." }
        format.json { head :unprocessable_entity }
      end
    end
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to notifications_path, alert: "Notification not found." }
      format.json { render json: { error: "Notification not found" }, status: :not_found }
    end
  end
end

