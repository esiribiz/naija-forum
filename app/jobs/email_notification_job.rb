class EmailNotificationJob < ApplicationJob
  queue_as :default

  # EmailNotificationJob handles sending various types of email notifications to users
  # 
  # @param user_id [Integer] The ID of the user to send the notification to
  # @param notification_type [String] The type of notification (e.g., 'welcome', 'new_comment', 'new_like')
  # @param content_id [Integer] Optional ID of related content (e.g., post_id, comment_id)
  # @param data [Hash] Optional additional data specific to the notification type
  def perform(user_id, notification_type, content_id = nil, data = {})
    # Find the user by ID
    user = User.find_by(id: user_id)
    
    unless user
      Rails.logger.error("EmailNotificationJob: User with ID #{user_id} not found")
      return
    end
    
    begin
      # Handle different notification types
      case notification_type
      when 'welcome'
        # Send welcome email to new users
        Rails.logger.info("Sending welcome email to user #{user.email}")
        UserMailer.welcome_email(user).deliver_now
        
      when 'new_comment'
        # Send notification about a new comment
        return unless content_id
        
        post = Post.find_by(id: content_id)
        unless post
          Rails.logger.error("EmailNotificationJob: Post with ID #{content_id} not found")
          return
        end
        
        Rails.logger.info("Sending new comment notification to user #{user.email} for post ##{post.id}")
        UserMailer.new_comment_email(user, post, data[:comment_text]).deliver_now
        
      when 'new_like'
        # Send notification about a new like on user's content
        return unless content_id
        
        # Determine what type of content was liked
        if data[:content_type] == 'post'
          post = Post.find_by(id: content_id)
          unless post
            Rails.logger.error("EmailNotificationJob: Post with ID #{content_id} not found")
            return
          end
          
          Rails.logger.info("Sending new like notification to user #{user.email} for post ##{post.id}")
          UserMailer.new_like_email(user, post, data[:liker_id]).deliver_now
        elsif data[:content_type] == 'comment'
          comment = Comment.find_by(id: content_id)
          unless comment
            Rails.logger.error("EmailNotificationJob: Comment with ID #{content_id} not found")
            return
          end
          
          Rails.logger.info("Sending new like notification to user #{user.email} for comment ##{comment.id}")
          UserMailer.new_comment_like_email(user, comment, data[:liker_id]).deliver_now
        end
        
      when 'password_reset'
        # Send password reset instructions
        Rails.logger.info("Sending password reset email to user #{user.email}")
        UserMailer.password_reset_email(user, data[:reset_token]).deliver_now
        
      else
        Rails.logger.error("EmailNotificationJob: Unknown notification type '#{notification_type}'")
      end
      
      # Record that notification was sent
      Rails.logger.info("Email notification '#{notification_type}' sent to user #{user.email}")
    rescue => e
      # Handle any errors that occur during email sending
      Rails.logger.error("EmailNotificationJob failed: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      
      # Optional: you might want to retry the job later or notify admins
      # retry_job(wait: 1.hour) if attempts < 3
    end
  end
end
