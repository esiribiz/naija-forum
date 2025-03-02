class CategoryPolicy < ApplicationPolicy
class Scope < Scope
    def resolve
    # Since categories are public, return all categories
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
    user&.admin?
end

def update?
    user&.admin?
end

def destroy?
    user&.admin?
end
end

