# Admin Security Configuration
# This file contains security configurations specifically for the admin interface

Rails.application.config.after_initialize do
  # Admin session timeout settings
  ADMIN_SESSION_TIMEOUT = {
    production: 30.minutes,
    staging: 1.hour,
    development: 2.hours,
    test: 2.hours
  }.freeze

  # Admin rate limiting (stricter than regular users)
  ADMIN_RATE_LIMITS = {
    user_creation: { requests: 10, period: 1.hour },
    role_changes: { requests: 20, period: 1.hour },
    user_deletion: { requests: 5, period: 1.hour },
    bulk_operations: { requests: 3, period: 1.hour }
  }.freeze

  # Security headers for admin interface
  ADMIN_SECURITY_HEADERS = {
    "Strict-Transport-Security" => "max-age=31536000; includeSubDomains",
    "X-Content-Type-Options" => "nosniff",
    "X-Frame-Options" => "DENY",
    "X-XSS-Protection" => "1; mode=block",
    "Referrer-Policy" => "strict-origin-when-cross-origin",
    "Permissions-Policy" => "geolocation=(), microphone=(), camera=()"
  }.freeze

  # Admin audit logging settings
  ADMIN_AUDIT_EVENTS = [
    "user_created",
    "user_deleted",
    "user_banned",
    "user_unbanned",
    "role_changed",
    "post_deleted",
    "comment_deleted",
    "category_created",
    "category_deleted"
  ].freeze

  # IP whitelist for admin access (empty means all IPs allowed)
  # In production, you should restrict admin access to specific IP ranges
  ADMIN_IP_WHITELIST = Rails.env.production? ? [] : []

  # Failed login attempt thresholds for admin users
  ADMIN_SECURITY_THRESHOLDS = {
    max_failed_logins: 3,
    lockout_duration: 1.hour,
    suspicious_activity_threshold: 2
  }.freeze
end
