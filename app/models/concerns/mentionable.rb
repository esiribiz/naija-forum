module Mentionable
extend ActiveSupport::Concern

included do
    after_create :notify_mentioned_users
end

private

def notify_mentioned_users
    mentions = content.scan(/@([\w-]+)/).flatten
    return if mentions.empty?

    users = User.where(username: mentions)
    users.each do |user|
    # You can implement actual notification logic here
    # For now, we'll just prepare for future notification implementation
    # Example: Notification.create(recipient: user, actor: self.user, action: 'mentioned', notifiable: self)
    end
end
end

