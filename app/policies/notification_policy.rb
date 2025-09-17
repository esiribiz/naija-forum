# frozen_string_literal: true

class NotificationPolicy < ApplicationPolicy
  # Users can view their own notifications
  def index?
    true
  end

  # Users can mark their own notifications as read
  def mark_as_read?
    user_owns_notification?
  end

  # Users can mark all their own notifications as read
  def mark_all_as_read?
    true
  end

  # Users can destroy their own notifications
  def destroy?
    user_owns_notification?
  end

  # Users can clear all their own notifications
  def clear?
    true
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      # Users can only access their own notifications
      scope.where(user: user)
    end
  end

  private

  def user_owns_notification?
    record.user == user
  end
end