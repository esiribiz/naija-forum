class User < ApplicationRecord
include Redis::Objects
# Include default devise modules. Others available are:
# :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable,
    :password_expirable, :password_archivable

# Keep the association but make security questions optional
has_many :security_questions, dependent: :destroy
accepts_nested_attributes_for :security_questions


# Associations
has_many :posts, dependent: :destroy
has_many :comments, dependent: :destroy
has_many :login_activities, dependent: :destroy
has_many :likes, dependent: :destroy
has_many :followings, class_name: "Follow", foreign_key: "follower_id", dependent: :destroy
has_many :followers, class_name: "Follow", foreign_key: "followed_id", dependent: :destroy
has_many :followed_users, through: :followings, source: :followed
has_many :following_users, through: :followers, source: :follower
has_many :following, class_name: 'Follow', foreign_key: 'follower_id', dependent: :destroy
has_many :liked_posts, through: :likes, source: :post
has_one_attached :avatar


# Constants
MAX_LOGIN_ATTEMPTS = 5
LOCKOUT_TIME = 30.minutes
PASSWORD_MIN_LENGTH = 12
PASSWORD_MAX_LENGTH = 128
USERNAME_MIN_LENGTH = 3
USERNAME_MAX_LENGTH = 30

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

# Password validations using strong_password gem
validates :password,
        password_strength: { min_entropy: 20 },
        length: { in: PASSWORD_MIN_LENGTH..PASSWORD_MAX_LENGTH },
        format: { 
            with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[[:^alnum:]])/x,
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

def suspicious_activity?
  # Skip suspicious activity checks in development and test environments
  return false if Rails.env.development? || Rails.env.test?
  
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

# Status methods
def online?
last_active_at.present? && last_active_at > 5.minutes.ago
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

def lock_access!
    super
    UserMailer.account_locked(self).deliver_later
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


end
