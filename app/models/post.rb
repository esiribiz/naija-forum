class Post < ApplicationRecord
include HtmlProcessor
include Redis::Objects

# Rate limiting
rate_limit_key = ->(post) { "post:#{post.user_id}:rate_limit" }
counter :posts_count, key: rate_limit_key
value :last_post_at, key: rate_limit_key

# Relationships
belongs_to :user, counter_cache: true
belongs_to :category, touch: true
has_many :comments, dependent: :destroy
has_many_attached :images
has_many :post_tags, dependent: :destroy
has_many :tags, through: :post_tags
has_many :mentions, as: :mentionable, dependent: :destroy
has_many :notifications, as: :notifiable, dependent: :destroy
has_many :likes, dependent: :destroy

# Validations
validates :title, presence: true, 
                length: { minimum: 3, maximum: 200 },
                format: { with: /\A[a-zA-Z0-9\s\-_.,!?()]+\z/, 
                        message: "contains invalid characters" }

validates :body, presence: true,
                length: { minimum: 10, maximum: 50000 }

validate :safe_html_content
validate :rate_limit_check, on: :create
validate :images_count
validate :images_size

# Callbacks
before_validation :sanitize_title
before_save :process_body
before_create :set_last_post_time
after_create :increment_posts_count, unless: -> { Rails.env.test? }

def tag_list
    tags.pluck(:name).join(", ")
end

def tag_list=(names)
    self.tags = names.split(",").map do |name|
    Tag.find_or_create_by(name: name.strip)
    end
end

private

def process_body
  # Process the body HTML (sanitize without auto-linking URLs)
  self.body = process_html(body) if body.present?
end

def safe_html_content
  return if body.blank?
  # Process HTML content without auto-linking URLs
  processed = process_html(body)
  if processed.blank?
    errors.add(:body, "contains invalid or unsafe HTML content")
  elsif processed.length < 10
    errors.add(:body, "is too short after HTML processing")
  end
end

def sanitize_title
self.title = ActionController::Base.helpers.sanitize(title, tags: [])
end

def rate_limit_check
return unless user
# Skip Redis-dependent validations in development environment
return if Rails.env.development?

last_time = last_post_at.value.to_f
current_time = Time.current.to_f

if current_time - last_time < 30.seconds
    errors.add(:base, "Please wait 30 seconds between posts")
end

# Skip the daily post limit check in the test environment
unless Rails.env.test?
  if posts_count.value.to_i >= 100 && Time.current.beginning_of_day.to_f < last_time
      errors.add(:base, "Daily post limit reached (100 posts)")
  end
end
end

def set_last_post_time
  # Skip Redis operations in development environment
  return if Rails.env.development?
  self.last_post_at.value = Time.current.to_f
end

def increment_posts_count
  # Skip Redis operations in development environment
  return if Rails.env.development?
  posts_count.increment
end

def images_count
return unless images.attached?
if images.length > 10
    errors.add(:images, "cannot attach more than 10 images")
end
end

def images_size
return unless images.attached?
images.each do |image|
    if image.blob.byte_size > 5.megabytes
    errors.add(:images, "size must be less than 5MB")
    end
    
    unless image.content_type.in?(%w[image/jpeg image/png image/gif])
    errors.add(:images, "must be JPEG, PNG, or GIF")
    end
end
end
end
