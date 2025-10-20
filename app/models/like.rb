class Like < ApplicationRecord
  belongs_to :user
  belongs_to :post

  validates :user, presence: true
  validates :post, presence: true
  validates :user_id, uniqueness: { scope: :post_id, message: "has already liked this post" }

  # Callbacks
  after_create :create_notification

  private

  # Create a notification for the post author when their post is liked
  def create_notification
    # Don't notify if the liker is the post author
    return if user_id == post.user_id

    Notification.notify(
      recipient: post.user,
      actor: user,
      action: "liked",
      notifiable: post
    )
  end
end
