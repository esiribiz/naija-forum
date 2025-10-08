class EmailNotificationJob < ApplicationJob
  queue_as :notifications

  def perform(notification_id)
    notification = Notification.find_by(id: notification_id)
    
    # Don't send emails for read notifications or if the recipient has disabled email notifications
    return if notification.read? || !notification.user.email_notifications_enabled?
    
    case notification.action
    when 'commented'
      UserMailer.new_comment_notification(notification).deliver_now
    when 'replied'
      UserMailer.reply_notification(notification).deliver_now
    when 'liked'
      UserMailer.new_like_notification(notification).deliver_now
    when 'mentioned'
      UserMailer.new_mention_notification(notification).deliver_now
    when 'followed'
      UserMailer.new_follower_notification(notification).deliver_now
    else
      UserMailer.general_notification(notification).deliver_now
    end
    
    # Mark notification as emailed
    notification.update(emailed: true)
  rescue => e
    Rails.logger.error "Error sending notification email: #{e.message}"
    # Consider retrying with exponential backoff for transient errors
    # retry_job wait: 1.minute if should_retry?(e)
  end
  
  private
  
  def should_retry?(error)
    # List of errors that might be transient and worth retrying
    [
      Net::SMTPServerBusy,
      Net::SMTPAuthenticationError,
      Net::ReadTimeout
    ].any? { |error_class| error.is_a?(error_class) }
  end
end
