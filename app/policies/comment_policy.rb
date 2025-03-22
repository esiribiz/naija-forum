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

def update?
    # Comment author or admin can update
    return false unless user.present?
    user.admin? || record.user_id == user.id
end

def destroy?
    # Comment author, post owner, or admin can delete
    return false unless user.present?
    user.admin? || record.user_id == user.id || user.id == record.post.user_id
end
end
