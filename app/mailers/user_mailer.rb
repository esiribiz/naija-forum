class UserMailer < ApplicationMailer
  default from: 'notifications@naija-forum.com'
  
  # Email notification for new comments on user's posts
  def new_comment_notification(notification)
    @notification = notification
    @recipient = notification.recipient
    @actor = notification.actor
    @comment = notification.notifiable
    @post = @comment.post
    
    mail(
      to: @recipient.email,
      subject: "#{@actor.username} commented on your post"
    )
  end
  
  # Email notification for new likes on user's content
  def new_like_notification(notification)
    @notification = notification
    @recipient = notification.recipient
    @actor = notification.actor
    @like = notification.notifiable
    
    # Determine if like is on a post or comment
    if @like.likeable_type == 'Post'
      @content = @like.likeable
      subject_text = "#{@actor.username} liked your post"
    else
      @content = @like.likeable
      subject_text = "#{@actor.username} liked your comment"
    end
    
    mail(
      to: @recipient.email,
      subject: subject_text
    )
  end
  
  # Email notification for mentions in posts or comments
  def new_mention_notification(notification)
    @notification = notification
    @recipient = notification.recipient
    @actor = notification.actor
    @mentionable = notification.notifiable
    
    if @mentionable.is_a?(Post)
      subject_text = "#{@actor.username} mentioned you in a post"
    else
      subject_text = "#{@actor.username} mentioned you in a comment"
    end
    
    mail(
      to: @recipient.email,
      subject: subject_text
    )
  end
  
  # Email notification for new followers
  def new_follower_notification(notification)
    @notification = notification
    @recipient = notification.recipient
    @actor = notification.actor
    @follow = notification.notifiable
    
    mail(
      to: @recipient.email,
      subject: "#{@actor.username} is now following you"
    )
  end
  
  # Generic email for other notification types
  def general_notification(notification)
    @notification = notification
    @recipient = notification.recipient
    @actor = notification.actor
    @notifiable = notification.notifiable
    
    mail(
      to: @recipient.email,
      subject: "New notification from Naija Forum"
    )
  end
end

