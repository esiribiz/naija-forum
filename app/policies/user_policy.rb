class UserPolicy < ApplicationPolicy
class Scope < Scope
    def resolve
    if user&.admin?
        scope.all
    else
        scope.where(id: user&.id)
    end
    end
end

def show?
    true # Everyone can view user profiles
end

def edit?
    user&.admin? || user == record
end

def update?
    edit?
end

def destroy?
    user&.admin?
end

private

def owner?
    user == record
end
end

