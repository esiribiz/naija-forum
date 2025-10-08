class User < ApplicationRecord
  include Redis::Objects
  extend FriendlyId
  
  # Include PgSearch::Model with error handling
  begin
    include PgSearch::Model
  rescue NameError => e
    Rails.logger.warn "PgSearch::Model not available: #{e.message}" if defined?(Rails)
  end
# FriendlyId configuration for SEO-friendly URLs
friendly_id :username, use: [:slugged, :finders]

# Full-text search configuration (only if PgSearch is available)
if respond_to?(:pg_search_scope)
  pg_search_scope :search_users,
    against: {
      username: 'A',
      first_name: 'B',
      last_name: 'B',
      bio: 'C'
    },
    using: {
      tsearch: {
        prefix: true,
        dictionary: 'english'
      },
      trigram: {
        threshold: 0.3
      }
    }
end
# Include default devise modules. Others available are:
# :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable,
    :trackable, :password_expirable, :password_archivable

# Activity-based scopes for admin filtering
scope :online, -> { where('last_sign_in_at > ? OR last_active_at > ?', 5.minutes.ago, 5.minutes.ago) }
scope :recently_active, -> { where('last_sign_in_at > ? OR last_active_at > ?', 1.day.ago, 1.day.ago) }
scope :inactive, -> { where('last_sign_in_at IS NOT NULL AND last_sign_in_at <= ?', 1.day.ago) }
scope :never_logged_in, -> { where(last_sign_in_at: nil) }
scope :joined_today, -> { where('created_at >= ?', Date.current) }
scope :joined_this_week, -> { where('created_at >= ?', 1.week.ago) }
scope :joined_this_month, -> { where('created_at >= ?', 1.month.ago) }
scope :joined_last_3_months, -> { where('created_at >= ?', 3.months.ago) }
scope :joined_this_year, -> { where('created_at >= ?', 1.year.ago) }
scope :by_posts_count, -> { left_joins(:posts).group('users.id').order('COUNT(posts.id) DESC') }
scope :by_comments_count, -> { left_joins(:comments).group('users.id').order('COUNT(comments.id) DESC') }
scope :most_active, -> { left_joins(:posts, :comments).group('users.id').order('(COUNT(DISTINCT posts.id) + COUNT(DISTINCT comments.id)) DESC') }

# Keep the association but make security questions optional
has_many :security_questions, dependent: :destroy
accepts_nested_attributes_for :security_questions


# Associations
has_many :posts, dependent: :destroy
has_many :comments, dependent: :destroy
has_many :login_activities, dependent: :destroy
has_many :likes, dependent: :destroy
has_many :mentions, dependent: :destroy
has_many :security_question_attempts, dependent: :destroy
has_many :notifications, foreign_key: "user_id", dependent: :destroy
has_many :actor_notifications, class_name: "Notification", foreign_key: "actor_id", dependent: :destroy
has_many :followings, class_name: "Follow", foreign_key: "follower_id", dependent: :destroy
has_many :followers, class_name: "Follow", foreign_key: "followed_id", dependent: :destroy
has_many :followed_users, through: :followings, source: :followed
has_many :follower_users, through: :followers, source: :follower
has_many :liked_posts, through: :likes, source: :post
has_one_attached :avatar


# Constants
MAX_LOGIN_ATTEMPTS = 5
LOCKOUT_TIME = 30.minutes
PASSWORD_MIN_LENGTH = 12
PASSWORD_MAX_LENGTH = 128
USERNAME_MIN_LENGTH = 3
USERNAME_MAX_LENGTH = 30
VALID_ROLES = %w[user admin moderator].freeze

# Username validations
validates :username,
        presence: true,
        uniqueness: { case_sensitive: false },
        length: { in: USERNAME_MIN_LENGTH..USERNAME_MAX_LENGTH },
        format: { 
            with: /\A[a-zA-Z0-9_-]+\z/,
            message: "can only contain letters, numbers, underscores and dashes"
        }

# Profile validations
validates :first_name, :last_name, length: { maximum: 50 }, allow_blank: true
validates :bio, length: { maximum: 650 }
validates :website, :twitter, :linkedin, :facebook,
        format: { with: /\Ahttps?:\/\/.+\z/, message: "must be a valid URL" },
        allow_blank: true

# Email validations (in addition to devise)
validates :email,
        presence: true,
        format: { with: URI::MailTo::EMAIL_REGEXP },
        uniqueness: { case_sensitive: false }

# Role validation
validates :role, inclusion: { in: VALID_ROLES, message: "must be one of: #{VALID_ROLES.join(', ')}" }

# Password validations using strong_password gem
validates :password,
        password_strength: { min_entropy: 20 },
        length: { in: PASSWORD_MIN_LENGTH..PASSWORD_MAX_LENGTH },
        format: { 
            with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[[:^alnum:]]).*\z/x,
            message: 'must contain at least one uppercase letter, one lowercase letter, one number, and one special character'
        },
        if: :password_required?

# Instance methods
def full_name
    return '' if first_name.blank? && last_name.blank?
    [first_name, last_name].compact.join(' ').strip
end

def display_name
    full_name.presence || username
end

def suspicious_activity?(ip_address)
  # Skip suspicious activity checks in development and test environments
  return false if Rails.env.development? || Rails.env.test?
  
  # Check if the current IP is from a restricted location or VPN/proxy
  if ip_address.present?
    # Check if current IP is from a restricted location
    if IpGeolocationService.restricted_location?(ip_address)
      Rails.logger.info("Login from restricted location detected for user #{id} - IP: #{ip_address}")
      return true
    end
    
    # Check if current IP is from a VPN or proxy
    vpn_detector = VpnProxyDetectionService.new
    if vpn_detector.vpn_or_proxy?(ip_address)
      Rails.logger.info("VPN/proxy detected for user #{id} from IP: #{ip_address}")
      return true
    end
  end
  
  # Get the user's recent login activities
  recent_logins = login_activities.recent.limit(10)
  return false if recent_logins.empty?
  
  # Check if any recent login is from a restricted location (African IPs)
  recent_logins.each do |login|
    if login.from_restricted_location?
      Rails.logger.info("Login from restricted location (African IP) detected for user #{id} - Country: #{login.country}")
      return true
    end
  end
  
  # Check if any recent login is from a VPN or proxy
  recent_logins.each do |login|
    next unless login.ip_address.present?
    vpn_detector = VpnProxyDetectionService.new
    if vpn_detector.vpn_or_proxy?(login.ip_address)
      Rails.logger.info("VPN/proxy detected for user #{id} from IP: #{login.ip_address}")
      return true
    end
  end
  
  # Check if there are suspicious login patterns (e.g., rapid logins from different locations)
  return true if recent_logins.first.suspicious_pattern?
  
  # Check for geographical anomalies (impossible travel between logins)
  if recent_logins.size >= 2
    current_login = recent_logins.first
    previous_login = recent_logins.second
    
    if current_login.login_at.present? && previous_login.login_at.present?
      time_diff_hours = (current_login.login_at - previous_login.login_at) / 3600.0
      
      # If both logins have location data
      if current_login.latitude.present? && current_login.longitude.present? &&
         previous_login.latitude.present? && previous_login.longitude.present?
         
        # Create location hashes for the IpGeolocationService
        current_location = {
          latitude: current_login.latitude,
          longitude: current_login.longitude
        }
        
        previous_location = {
          latitude: previous_login.latitude,
          longitude: previous_login.longitude
        }
        
        # Check if travel between logins is suspiciously fast
        if IpGeolocationService.suspicious_travel?(previous_location, current_location, time_diff_hours)
          return true
        end
      end
    end
  end
  
  # Check if the most recent login was during unusual hours in user's local timezone
  most_recent = recent_logins.first
  if most_recent && most_recent.latitude.present? && most_recent.longitude.present?
    location_data = {
      latitude: most_recent.latitude,
      longitude: most_recent.longitude,
      timezone: most_recent.timezone
    }
    
    if IpGeolocationService.unusual_hours?(location_data, most_recent.login_at)
      return true
    end
  end
  
  # Additional security check: flag accounts with too many login failures
  failed_logins_count = login_activities.failed.where(created_at: 24.hours.ago..Time.current).count
  return true if failed_logins_count >= 5
  
  # No suspicious activity detected
  false
end

def track_activity(ip_address)
    Rails.logger.info("User #{id} activity tracked from IP: #{ip_address}")
end
# Callbacks
before_validation :sanitize_user_input
# Security questions are now optional
# before_validation :build_security_questions, if: -> { new_record? && security_questions.empty? }
after_update :send_role_change_notification, if: :saved_change_to_role?

# Status methods
def online?
  # Check if user is currently online (signed in within last 5 minutes)
  (last_sign_in_at.present? && last_sign_in_at > 5.minutes.ago) ||
  (last_active_at.present? && last_active_at > 5.minutes.ago)
end

def recently_active?
  # User was active within the last 24 hours
  (last_sign_in_at.present? && last_sign_in_at > 1.day.ago) ||
  (last_active_at.present? && last_active_at > 1.day.ago)
end

def inactive?
  # User has signed in before but not recently
  last_sign_in_at.present? && last_sign_in_at <= 1.day.ago
end

def never_logged_in?
  # User created account but never signed in
  last_sign_in_at.blank?
end

def activity_status
  return 'online' if online?
  return 'recent' if recently_active?
  return 'never' if never_logged_in?
  return 'inactive'
end
# Rate limiting using Redis
counter :password_reset_attempts, expireat: -> { 1.hour.from_now }
counter :failed_login_attempts, expireat: -> { 1.hour.from_now }

def can_reset_password?
password_reset_attempts.value < 3
end

def can_attempt_login?
failed_login_attempts.value < MAX_LOGIN_ATTEMPTS
end

def register_failed_login
failed_login_attempts.increment
end

def register_password_reset_attempt
password_reset_attempts.increment
end

# Session and token management

def active_for_authentication?
super && !suspended?
end

def admin?
    role == "admin"
end

def moderator?
    role == "moderator"
end

def staff?
    admin? || moderator?
end

def suspended?
    suspended == true
end

def lock_access!
    super
    UserMailer.account_locked(self).deliver_later
end

# Notification methods

# Get a limited number of recent notifications
def recent_notifications(limit = 5)
  notifications.order(created_at: :desc).limit(limit)
end

# Get recent activity (posts and comments combined)
def recent_activity(limit = 10)
  activities = []
  
  # Get recent posts
  recent_posts = posts.order(created_at: :desc).limit(limit)
  recent_posts.each do |post|
    activities << {
      type: 'post',
      object: post,
      created_at: post.created_at
    }
  end
  
  # Get recent comments
  recent_comments = comments.includes(:post).order(created_at: :desc).limit(limit)
  recent_comments.each do |comment|
    activities << {
      type: 'comment',
      object: comment,
      created_at: comment.created_at
    }
  end
  
  # Sort by date and limit
  activities.sort_by { |activity| activity[:created_at] }.reverse.first(limit)
end

# Get all unread notifications
def unread_notifications
  notifications.where(read: false)
end

# Mark all notifications as read
def mark_all_notifications_as_read
  notifications.where(read: false).update_all(read: true)
end

# Determines if user should receive email notifications
# This can be extended with a user preference in the future
def email_notifications_enabled?
    # By default, all users receive email notifications unless they've opted out
    # In a future implementation, this could check a database column for user preferences
    true
end

def reset_password!
if can_reset_password?
    register_password_reset_attempt
    super
else
    errors.add(:base, "Too many password reset attempts. Please try again later.")
    false
end
end

private

def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
end

def sanitize_user_input
    self.username = username.to_s.strip
    self.bio = ActionController::Base.helpers.sanitize(bio)
end

# Builds exactly 3 empty security questions for a new user
# This is now optional and can be called manually when needed
def build_security_questions
    3.times { security_questions.build } if security_questions.empty?
end

# Override security questions required method to make questions optional
def security_questions_required?
    false
end

# Send email notification when role changes
def send_role_change_notification
  # Get the current admin user who made the change
  # This will need to be set in a thread-local variable or passed via context
  admin_user = Thread.current[:current_admin_user] || User.where(role: 'admin').first
  
  # Skip if no admin user found or if this is the initial role assignment
  return unless admin_user && saved_change_to_role?
  
  old_role, new_role = saved_change_to_role
  
  # Skip if this is the initial role assignment (from nil to something)
  return if old_role.blank?
  
  # Don't send email to the admin who made the change (unless changing their own role)
  return if self == admin_user
  
  begin
    UserMailer.role_change_notification(self, old_role, new_role, admin_user).deliver_later
    Rails.logger.info "Role change email sent to #{email} - Role changed from #{old_role} to #{new_role}"
  rescue => e
    Rails.logger.error "Failed to send role change email to #{email}: #{e.message}"
  end
end
end
