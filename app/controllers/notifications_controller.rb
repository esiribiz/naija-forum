# frozen_string_literal: true

class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notification, only: [:mark_as_read, :destroy]
  before_action :set_user_for_sidebar

  # GET /notifications
  def index
    @notifications = policy_scope(Notification)
                              .includes(:actor, :notifiable)
                              .order(created_at: :desc)
                              .page(params[:page])
                              .per(10)
    @unread_count = current_user.notifications.unread.count
    
    respond_to do |format|
      format.html
      format.json { render json: @notifications }
    end
  end

  # POST /notifications/:id/mark_as_read
  def mark_as_read
    authorize @notification
    if @notification.update(read: true)
      respond_to do |format|
        format.html { redirect_back(fallback_location: notifications_path, notice: "Notification marked as read.") }
        format.json { render json: @notification }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("notification_#{@notification.id}", partial: "notifications/notification", locals: { notification: @notification }) }
      end
    else
      respond_to do |format|
        format.html { redirect_back(fallback_location: notifications_path, alert: "Could not mark notification as read.") }
        format.json { render json: @notification.errors, status: :unprocessable_entity }
        format.turbo_stream { head :unprocessable_entity }
      end
    end
  end

  # POST /notifications/mark_all_as_read
  def mark_all_as_read
    authorize :notification, :mark_all_as_read?
    if current_user.notifications.unread.update_all(read: true)
      respond_to do |format|
        format.html { redirect_back(fallback_location: notifications_path, notice: "All notifications marked as read.") }
        format.json { head :no_content }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("notifications", partial: "notifications/notifications", locals: { notifications: current_user.notifications.includes(:actor, :notifiable).order(created_at: :desc) }) }
      end
    else
      respond_to do |format|
        format.html { redirect_back(fallback_location: notifications_path, alert: "Could not mark all notifications as read.") }
        format.json { head :unprocessable_entity }
        format.turbo_stream { head :unprocessable_entity }
      end
    end
  end

  # DELETE /notifications/:id
  def destroy
    authorize @notification
    if @notification.destroy
      respond_to do |format|
        format.html { redirect_back(fallback_location: notifications_path, notice: "Notification was successfully deleted.") }
        format.json { head :no_content }
        format.turbo_stream { render turbo_stream: turbo_stream.remove("notification_#{@notification.id}") }
      end
    else
      respond_to do |format|
        format.html { redirect_back(fallback_location: notifications_path, alert: "Could not delete notification.") }
        format.json { render json: @notification.errors, status: :unprocessable_entity }
        format.turbo_stream { head :unprocessable_entity }
      end
    end
  end

  # DELETE /notifications/clear
  def clear
    authorize :notification, :clear?
    if current_user.notifications.destroy_all
      respond_to do |format|
        format.html { redirect_to notifications_path, notice: "All notifications cleared." }
        format.json { head :no_content }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("notifications", partial: "notifications/notifications", locals: { notifications: [] }) }
      end
    else
      respond_to do |format|
        format.html { redirect_to notifications_path, alert: "Could not clear notifications." }
        format.json { head :unprocessable_entity }
        format.turbo_stream { head :unprocessable_entity }
      end
    end
  end

  private

  # Set @user for sidebar
  def set_user_for_sidebar
    @user = current_user
  end

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to notifications_path, alert: "Notification not found." }
      format.json { render json: { error: "Notification not found" }, status: :not_found }
      format.turbo_stream { head :not_found }
    end
  end
end
