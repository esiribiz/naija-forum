class Comment < ApplicationRecord
  include Mentionable
  include HtmlProcessor

  belongs_to :user, counter_cache: true
  belongs_to :post, counter_cache: true
  belongs_to :parent, class_name: "Comment", optional: true
  has_many :replies, class_name: "Comment", foreign_key: "parent_id", dependent: :destroy

  # Scope for top-level comments
  scope :top_level, -> { where(parent_id: nil) }

  validates :content, presence: true
  validates :user, presence: true
  validates :post, presence: true

  validate :prevent_self_reply

  before_save :process_html_content
  after_create :notify_post_author, :notify_parent_comment_author

  def can_be_edited_by?(user)
    user == self.user && Time.current - created_at < 2.minutes
  end

  def can_be_deleted_by?(user)
    user == self.user && Time.current - created_at < 2.minutes
  end

  private

  def prevent_self_reply
    if parent.present? && parent.user_id == user_id
      errors.add(:base, "Cannot reply to your own comment")
    end
  end

  def notify_post_author
    return if user_id == post.user_id
    Notification.notify(
      recipient: post.user,
      actor: user,
      action: "commented",
      notifiable: self
    )
  end

  def notify_parent_comment_author
    return unless parent.present?
    return if user_id == parent.user_id
    return if user_id == post.user_id && parent.user_id == post.user_id
    Notification.notify(
      recipient: parent.user,
      actor: user,
      action: "replied",
      notifiable: self
    )
  end

  def process_html_content
    self.content = process_html(content) if content.present?
  end
end
