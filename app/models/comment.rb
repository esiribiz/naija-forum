class Comment < ApplicationRecord
include Mentionable
include HtmlProcessor

belongs_to :user, counter_cache: true
belongs_to :post, counter_cache: true
belongs_to :parent, class_name: "Comment", optional: true
has_many :replies, class_name: "Comment", foreign_key: "parent_id", dependent: :destroy

validates :content, presence: true
validates :user, presence: true
validates :post, presence: true

validate :prevent_self_reply
validate :prevent_nested_replies

scope :top_level, -> { where(parent_id: nil) }

before_save :process_html_content
after_create :notify_post_author

private

def prevent_self_reply
    if parent.present? && parent.user_id == user_id
    errors.add(:base, "Cannot reply to your own comment")
    end
end

def prevent_nested_replies
    if parent.present? && parent.parent_id.present?
    errors.add(:base, "Cannot create nested replies beyond one level")
    end
end

def notify_post_author
    return if user_id == post.user_id # Don't notify if commenter is the post author
    # Implement notification logic here
    # Example: Notification.create(recipient: post.user, actor: user, action: 'commented', notifiable: self)
end

# Sanitizes HTML content without auto-linking URLs to prevent XSS attacks
# The HtmlProcessor module provides the process_html method that strips unsafe HTML
def process_html_content
    if content.present?
    self.content = process_html(content)
    end
end
end
