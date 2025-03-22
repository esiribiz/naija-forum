class PostPolicy < ApplicationPolicy
class Scope < Scope
    def resolve
    # Return all published posts for regular users
    # Admins can see all posts including drafts
    if user&.admin?
        scope.all
    else  
        scope.where(published: true)
    end
    end
end

def index?
    true
end

def show?
    # Anyone can see published posts
    # Author can see their own unpublished posts 
    # Admins can see all posts
    record.published? || user&.admin? || record.user_id == user&.id
end

def create?
    user.present?
end

def update?
    return false unless user.present?
    user.admin? || owner?
end

def destroy?
    return false unless user.present?
    user.admin? || owner?
end

private

def owner?
    record.user_id == user.id
end
end

