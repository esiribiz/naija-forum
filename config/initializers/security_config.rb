# frozen_string_literal: true

class SecurityConfig
class << self
    # Environment-specific configurations
    def environment_config
    @environment_config ||= {
        development: {
        session_timeout: 8.hours,
        max_login_attempts: 10,
        lockout_duration: 1.hour,
        strict_transport_security: false
        },
        test: {
        session_timeout: 8.hours,
        max_login_attempts: 10,
        lockout_duration: 1.hour,
        strict_transport_security: false
        },
        production: {
        session_timeout: 2.hours,
        max_login_attempts: 5,
        lockout_duration: 24.hours,
        strict_transport_security: true
        }
    }.freeze
    end

    # Session Configuration
    def session_config
    {
        key: '_app_session',
        http_only: true,
        secure: force_ssl?,
        expire_after: current_env_config[:session_timeout],
        same_site: :strict
    }
    end

    # Cookie Configuration
    def cookie_config
    {
        secure: force_ssl?,
        http_only: true,
        same_site: :strict,
        expire_after: current_env_config[:session_timeout]
    }
    end

    # Rate Limiting Configuration
    def rate_limit_config
    {
        authentication: {
        limit: 5,
        period: 5.minutes
        },
        api: {
        limit: 100,
        period: 1.hour
        },
        user_actions: {
        limit: 30,
        period: 1.minute
        }
    }
    end

    # Security Headers Configuration
    def security_headers
    {
        'X-Frame-Options' => 'SAMEORIGIN',
        'X-XSS-Protection' => '1; mode=block',
        'X-Content-Type-Options' => 'nosniff',
        'X-Download-Options' => 'noopen',
        'X-Permitted-Cross-Domain-Policies' => 'none',
        'Referrer-Policy' => 'strict-origin-when-cross-origin'
    }.merge(content_security_policy_headers)
    end

    # Content Security Policy
    def content_security_policy_headers
    script_src = %w['self']
    
    # Allow unsafe-inline and unsafe-eval in development for Stimulus and debugging
    if Rails.env.development?
        script_src += %w['unsafe-inline' 'unsafe-eval']
    end
    
    {
        'Content-Security-Policy' => [
        "default-src 'self'",
        "img-src 'self' data: blob: https:",
        "script-src #{script_src.join(' ')}",
        "style-src 'self' 'unsafe-inline'",
        "font-src 'self' data:",
        "form-action 'self'",
        "frame-ancestors 'none'",
        "connect-src 'self' ws: wss:"
        ].join('; ')
    }
    end

    # IP Blocking Configuration
    def ip_blocking_config
    {
        max_bad_requests: 100,
        block_duration: 1.hour,
        whitelist: ['127.0.0.1'],
        blacklist: []
    }
    end

    # Password Requirements
    def password_requirements
    {
        min_length: 12,
        max_length: 128,
        min_uppercase: 1,
        min_lowercase: 1,
        min_digits: 1,
        min_special_chars: 1,
        max_repeated_chars: 3,
        password_history: 5
    }
    end

    # Authentication Configuration
    def auth_config
    {
        max_login_attempts: current_env_config[:max_login_attempts],
        lockout_duration: current_env_config[:lockout_duration],
        password_expiry: 90.days,
        remember_for: 2.weeks,
        totp_enabled: true
    }
    end

    # Security Validation Methods
    def valid_password?(password)
    return false if password.length < password_requirements[:min_length]
    return false if password.length > password_requirements[:max_length]
    return false unless password.match?(/[A-Z]/)
    return false unless password.match?(/[a-z]/)
    return false unless password.match?(/[0-9]/)
    return false unless password.match?(/[!@#$%^&*(),.?":{}|<>]/)
    true
    end

    def valid_ip?(ip)
    return true if ip_blocking_config[:whitelist].include?(ip)
    return false if ip_blocking_config[:blacklist].include?(ip)
    true
    end

    private

    def current_env_config
    environment_config[Rails.env.to_sym] || environment_config[:production]
    end

    def force_ssl?
    Rails.env.production? || current_env_config[:strict_transport_security]
    end
end
end

