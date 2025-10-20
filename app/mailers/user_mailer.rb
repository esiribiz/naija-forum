class UserMailer < ApplicationMailer
  default from: "notifications@naija-forum.com"

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

  # Email notification for replies to user's comments
  def reply_notification(notification)
    @notification = notification
    @recipient = notification.recipient
    @actor = notification.actor
    @notifiable = notification.notifiable

    mail(
      to: @recipient.email,
      subject: "#{@actor.username} replied to your comment"
    )
  end

  # Email notification for new likes on user's content
  def new_like_notification(notification)
    @notification = notification
    @recipient = notification.recipient
    @actor = notification.actor
    @like = notification.notifiable

    # Determine if like is on a post or comment
    if @like.likeable_type == "Post"
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

  # Email notification for role changes
  def role_change_notification(user, old_role, new_role, admin_user)
    @user = user
    @old_role = old_role
    @new_role = new_role
    @admin_user = admin_user
    @promotion = role_priority(new_role) > role_priority(old_role)

    subject_text = if @promotion
      "Congratulations! Your role has been updated to #{new_role.capitalize}"
    else
      "Your account role has been changed to #{new_role.capitalize}"
    end

    mail(
      to: @user.email,
      subject: subject_text
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

  private

  def role_priority(role)
    case role.to_s.downcase
    when "admin"
      3
    when "moderator"
      2
    when "user"
      1
    else
      0
    end
  end
end
