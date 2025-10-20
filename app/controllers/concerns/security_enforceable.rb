module SecurityEnforceable
    extend ActiveSupport::Concern

    included do
      before_action :authenticate_user!
      before_action :enforce_security_headers
      before_action :check_rate_limit
      before_action :sanitize_request_parameters

      protect_from_forgery with: :exception, prepend: true

      rescue_from SecurityError, with: :handle_security_violation
      rescue_from RateLimitExceeded, with: :handle_rate_limit_exceeded
    end

    private

    def enforce_security_headers
      # Only set basic security headers in development, no CSP
      # CSP is handled by Rails configuration (disabled in development)
      return if Rails.env.development? # Skip all security headers in development

      response.headers["X-Frame-Options"] = "SAMEORIGIN"
      response.headers["X-XSS-Protection"] = "1; mode=block"
      response.headers["X-Content-Type-Options"] = "nosniff"
      response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    end

    def check_rate_limit
      # Skip rate limiting in development and test environments
      return if Rails.env.development? || Rails.env.test?

      key = "rate_limit:#{current_user&.id || request.remote_ip}:#{controller_name}:#{action_name}"

      begin
        REDIS.with do |redis|
          # Use pipelining to combine multiple Redis commands
          _, new_count, _ = redis.pipelined do |pipe|
            pipe.get(key)
            pipe.incr(key)
            pipe.expire(key, rate_limit_period)
          end

          # Check if rate limit exceeded (using the incremented count)
          count = new_count.to_i

          if count > max_requests_per_period
            log_security_event("Rate limit exceeded", severity: :warn)
            raise RateLimitExceeded
          end
        end
      rescue Redis::BaseError => e
        Rails.logger.error("Redis error in rate limiting: #{e.message}")
        # Fall through - don't enforce rate limiting if Redis is down
      end
    end

    def sanitize_request_parameters
      params.each do |key, value|
        next if key.in?(%w[controller action])
        params[key] = sanitize_value(value)
      end
    end

    def sanitize_value(value)
      case value
      when String
        ActionController::Base.helpers.sanitize(value)
      when Hash
        value.transform_values { |v| sanitize_value(v) }
      when Array
        value.map { |v| sanitize_value(v) }
      else
        value
      end
    end

    def authorize_user!(action = nil)
      unless current_user&.can?(action || "#{controller_name}:#{action_name}")
        log_security_event("Unauthorized access attempt", severity: :warn)
        raise SecurityError, "Unauthorized access"
      end
    end

    def verify_authenticity_token
      super
    rescue ActionController::InvalidAuthenticityToken
      log_security_event("CSRF token verification failed", severity: :error)
      raise SecurityError, "Invalid authenticity token"
    end

    def log_security_event(message, severity: :info)
      Rails.logger.tagged("SECURITY") do
        context = {
          user_id: current_user&.id,
          ip: request.remote_ip,
          path: request.fullpath,
          user_agent: request.user_agent,
          timestamp: Time.current
        }

        Rails.logger.public_send(severity, "#{message} | #{context.to_json}")
      end
    end

    def handle_security_violation(exception)
      log_security_event(exception.message, severity: :error)

      respond_to do |format|
        format.html { redirect_to root_path, alert: "Security violation detected." }
        format.json { render json: { error: "Security violation" }, status: :forbidden }
      end
    end

    def handle_rate_limit_exceeded
      response.headers["Retry-After"] = rate_limit_period.to_s

      respond_to do |format|
        format.html { render html: "<h1>Too Many Requests</h1><p>Please try again later.</p>".html_safe, status: :too_many_requests }
        format.json { render json: { error: "Rate limit exceeded" }, status: :too_many_requests }
      end
    end

    def max_requests_per_period
      100 # Configurable per environment
    end

    def rate_limit_period
      1.hour.to_i # Configurable per environment
    end

    # Correctly closed class definitions
    class SecurityError < StandardError; end
    class RateLimitExceeded < StandardError; end
  end
