# frozen_string_literal: true

class UserSerializer
  include JSONAPI::Serializer
  
  set_type :user
  set_id :id
  
  attributes :username, :first_name, :last_name, :bio, :location, :website,
             :twitter, :linkedin, :facebook, :created_at, :updated_at, :role,
             :posts_count, :comments_count, :last_active_at
  
  # Computed attributes
  attribute :display_name do |user|
    user.display_name
  end
  
  attribute :full_name do |user|
    user.full_name
  end
  
  attribute :avatar_url do |user|
    if user.avatar.attached?
      Rails.application.routes.url_helpers.url_for(user.avatar)
    else
      nil
    end
  end
  
  attribute :online do |user|
    user.online?
  end
  
  attribute :is_staff do |user|
    user.staff?
  end
  
  # Relationships
  has_many :posts, serializer: :post
  has_many :comments, serializer: :comment
  
  # Conditional attributes (only for current user or admins)
  attribute :email, if: proc { |user, params|
    current_user = params[:current_user]
    current_user && (current_user == user || current_user.admin?)
  }
  
  attribute :suspended, if: proc { |user, params|
    current_user = params[:current_user]
    current_user && (current_user == user || current_user.staff?)
  }
  
  # Safe URLs helper
  attribute :safe_website do |user|
    ApplicationHelper.new.safe_external_url(user.website) if user.website.present?
  end
  
  attribute :safe_twitter do |user|
    ApplicationHelper.new.safe_external_url(user.twitter) if user.twitter.present?
  end
  
  attribute :safe_linkedin do |user|
    ApplicationHelper.new.safe_external_url(user.linkedin) if user.linkedin.present?
  end
  
  attribute :safe_facebook do |user|
    ApplicationHelper.new.safe_external_url(user.facebook) if user.facebook.present?
  end
end