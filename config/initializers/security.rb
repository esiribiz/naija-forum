# frozen_string_literal: true

# Configure Rack::Attack for rate limiting
Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

# Throttle high-volume requests
Rack::Attack.throttle("req/ip", limit: 300, period: 5.minutes) do |req|
req.ip
end

# Throttle login attempts
Rack::Attack.throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
if req.path == "/users/sign_in" && req.post?
    req.ip
end
end

# Block suspicious requests
Rack::Attack.blocklist("block bad UA") do |req|
req.user_agent =~ /^$/
end

# Configure secure headers
if Rails.env.development?
  # Minimal configuration for development - allows JavaScript debugging without CSP restrictions
  SecureHeaders::Configuration.default do |config|
    # Disable most security headers in development for easier debugging
    config.cookies = {
        secure: true,  # Must be true per SecureHeaders validation
        httponly: true,
        samesite: {
            lax: true   # More permissive for development
        }
    }

    # Disable restrictive headers in development
    config.x_frame_options = nil
    config.x_content_type_options = nil
    config.x_xss_protection = nil
    config.x_download_options = nil
    config.x_permitted_cross_domain_policies = nil
    config.referrer_policy = nil

    # No CSP in development to allow inline scripts/styles and importmap
    config.csp = SecureHeaders::OPT_OUT
    config.hsts = SecureHeaders::OPT_OUT
  end
else
  # Production configuration with full security headers
  SecureHeaders::Configuration.default do |config|
    config.cookies = {
        secure: true,
        httponly: true,
        samesite: {
        strict: true
        }
    }

    config.x_frame_options = "DENY"
    config.x_content_type_options = "nosniff"
    config.x_xss_protection = "1; mode=block"
    config.x_download_options = "noopen"
    config.x_permitted_cross_domain_policies = "none"
    config.referrer_policy = %w(strict-origin-when-cross-origin)

    config.csp = {
        default_src: %w('self'),
        img_src: %w('self' data: https:),
        media_src: %w('self'),
        script_src: %w('self'),
        style_src: %w('self' 'unsafe-inline'),
        form_action: %w('self'),
        frame_ancestors: %w('none'),
        upgrade_insecure_requests: true
    }

    config.hsts = "max-age=31536000; includeSubDomains; preload"
  end
end

# Configure CORS
Rails.application.config.middleware.insert_before 0, Rack::Cors do
allow do
    origins "*"
    resource "/api/*",
    headers: :any,
    methods: [:get, :post, :patch, :put, :delete],
    expose: ["Authorization"],
    max_age: 600
end
end

# Configure Action Dispatch
Rails.application.config.action_dispatch.cookies_same_site_protection = :strict

# Configure Session Store
Rails.application.config.session_store :cookie_store,
key: "_app_session",
secure: Rails.env.production?,
httponly: true,
expire_after: 12.hours,
same_site: :strict

# Additional security configurations
Rails.application.config.ssl_options = { 
  hsts: true, 
  redirect: { 
    exclude: ->(request) { request.path == "/up" }
  }
}
Rails.application.config.force_ssl = Rails.env.production?
Rails.application.config.action_controller.per_form_csrf_tokens = true
Rails.application.config.action_controller.forgery_protection_origin_check = true

# Configure filter parameters
Rails.application.config.filter_parameters += [
:passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn
]
