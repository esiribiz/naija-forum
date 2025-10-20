# frozen_string_literal: true

# Configure Sentry for error monitoring
if Rails.env.production? && ENV["SENTRY_DSN"].present?
  Sentry.init do |config|
    config.dsn = ENV["SENTRY_DSN"]

    # Set environment and release information
    config.environment = Rails.env
    config.release = ENV.fetch("GIT_COMMIT_SHA", "unknown")

    # Performance monitoring - sample 10% of transactions in production
    config.traces_sample_rate = 0.1

    # Capture user information
    config.send_default_pii = true

    # Filter sensitive parameters
    config.before_send = lambda do |event, _hint|
      # Don't send events for certain exception types
      return nil if event.exception&.values&.any? { |ex|
        ex[:type] == "ActionController::RoutingError" ||
        ex[:type] == "ActionController::UnknownFormat"
      }

      # Filter out sensitive information
      if event.request&.data
        event.request.data = event.request.data.except(
          "password", "password_confirmation", "current_password",
          "secret", "token", "api_key", "private_key"
        )
      end

      event
    end

    # Set breadcrumbs configuration
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]

    # Configure which exceptions to ignore
    config.excluded_exceptions += [
      "ActionController::BadRequest",
      "ActionController::UnknownFormat",
      "ActionController::RoutingError",
      "ActionDispatch::RemoteIp::IpSpoofAttackError",
      "Rack::QueryParser::InvalidParameterError",
      "Rack::QueryParser::ParameterTypeError"
    ]

    # Tag events with additional context
    config.tags = {
      component: "naija-forum",
      server: ENV.fetch("HOSTNAME", "unknown")
    }
  end

  # Configure Rails integration
  Rails.application.configure do
    config.sentry.rails.report_rescued_exceptions = true
    config.sentry.rails.capture_exceptions = true
  end
end

# Development/test configuration
unless Rails.env.production?
  Rails.logger.info "Sentry is disabled in #{Rails.env} environment"
end
