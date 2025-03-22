# frozen_string_literal: true

class Notification < ApplicationRecord
  # Associations
  belongs_to :user # receiver of the notification
  belongs_to :notifiable, polymorphic: true # the object that generated the notification
  belongs_to :actor, class_name: 'User', optional: true # user who triggered the notification

  # Callbacks
  after_create :send_email_notification

  # Attributes
  # - action (string): type of notification (e.g. 'liked', 'commented', 'mentioned')
  # - read (boolean): whether the notification has been read

  # Validations
  validates :action, presence: true
  validates :read, inclusion: { in: [true, false] }
  
  # Scopes
  scope :unread, -> { where(read: false) }
  scope :read, -> { where(read: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }
  scope :by_action, ->(action) { where(action: action) }
  scope :from_last_week, -> { where('created_at >= ?', 1.week.ago) }
  scope :from_actor, ->(actor) { where(actor: actor) }
  
  # Default ordering
  default_scope { order(created_at: :desc) }
  
  # Mark notification as read
  def mark_as_read!
    update!(read: true)
  end
  
  # Mark notification as unread
  def mark_as_unread!
    update!(read: false)
  end
  
  # Check if notification is read
  def read?
    read
  end
  
  # Check if notification is unread
  def unread?
    !read
  end
  
  # Humanized notification text
  def text
    case action
    when 'liked'
      "#{actor&.username || 'Someone'} liked your #{notifiable_type.downcase}"
    when 'commented'
      "#{actor&.username || 'Someone'} commented on your #{notifiable_type.downcase}"
    when 'mentioned'
      "#{actor&.username || 'Someone'} mentioned you in a #{notifiable_type.downcase}"
    when 'followed'
      "#{actor&.username || 'Someone'} started following you"
    else
      "You have a new notification"
    end
  end
  
  # Time ago in words helper
  def time_ago
    ActionView::Helpers::DateHelper.time_ago_in_words(created_at)
  end
  
  # Class methods
  class << self
    # Mark all notifications as read for a user
    def mark_all_as_read_for(user)
      for_user(user).unread.update_all(read: true)
    end
    
    # Count unread notifications for a user
    def unread_count_for(user)
      for_user(user).unread.count
    end
    
    # Create a notification with standard parameters
    def notify(recipient:, actor: nil, action:, notifiable:)
      create(
        user: recipient,
        actor: actor,
        action: action,
        notifiable: notifiable,
        read: false
      )
    end
  end
  
  private
  
  # Send email notification if the user has enabled email notifications
  def send_email_notification
    EmailNotificationJob.perform_later(self.id) if user.email_notifications_enabled?
  end
end
