class CommentPolicy < ApplicationPolicy
class Scope < Scope
    def resolve
    # By default, users can see all comments
    scope.all
    end
end

def index?
    true
end

def show?
    true
end

def create?
    # Any logged in user can comment or reply
    user.present?
end

def edit?
    update?
end

def update?
    # Comment author or admin can update (with time restrictions for regular users)
    return false unless user.present?
    return true if user.admin?
    return false unless record.user_id == user.id
    record.can_be_edited_by?(user)
end

def destroy?
    # Comment author, post owner, or admin can delete (with time restrictions for comment authors)
    return false unless user.present?
    return true if user.admin?
    return true if user.id == record.post.user_id  # Post authors can always delete comments on their posts
    return false unless record.user_id == user.id
    record.can_be_deleted_by?(user)
end
end
