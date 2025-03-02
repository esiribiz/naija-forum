# frozen_string_literal: true

class Notification < ApplicationRecord
  # Associations
  belongs_to :user # receiver of the notification
  belongs_to :notifiable, polymorphic: true # the object that generated the notification
  belongs_to :actor, class_name: 'User', optional: true # user who triggered the notification

  # Attributes
  # - action (string): type of notification (e.g. 'liked', 'commented', 'mentioned')
  # - read (boolean): whether the notification has been read

  # Validations
  validates :action, presence: true
  validates :read, inclusion: { in: [true, false] }
  
  # Scopes
  scope :unread, -> { where(read: false) }
  scope :read, -> { where(read: true) }
  
  # Mark notification as read
  def mark_as_read!
    update!(read: true)
  end
  
  # Mark notification as unread
  def mark_as_unread!
    update!(read: false)
  end
end

