class NotificationChannel < ApplicationCable::Channel
  def subscribed
    if current_user
      stream_from "user_notifications_#{current_user.id}"
      Rails.logger.info "User #{current_user.id} subscribed to notifications"
    else
      reject
    end
  end

  def unsubscribed
    Rails.logger.info "User unsubscribed from notifications"
    # Any cleanup needed when channel is unsubscribed
  end
end