# frozen_string_literal: true

require "redis"
require "connection_pool"

# -------------------------------------------------------------------
# Redis configuration
# -------------------------------------------------------------------

redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")

redis_config = {
  url: redis_url,
  reconnect_attempts: 5,
  connect_timeout: 5,
  read_timeout: 5,
  write_timeout: 5
}

pool_size    = ENV.fetch("REDIS_POOL_SIZE", 5).to_i
pool_timeout = ENV.fetch("REDIS_POOL_TIMEOUT", 5).to_i

# -------------------------------------------------------------------
# Connection pool
# -------------------------------------------------------------------

REDIS = ConnectionPool.new(size: pool_size, timeout: pool_timeout) do
  Redis.new(redis_config)
end

# redis-objects integration
Redis::Objects.redis = REDIS

# -------------------------------------------------------------------
# Safe startup check (DO NOT CRASH BOOT)
# -------------------------------------------------------------------

unless Rails.env.test? || ENV["SKIP_REDIS_CONNECTION"] || ENV["SECRET_KEY_BASE_DUMMY"]
  begin
    REDIS.with { |redis| redis.ping }
    Rails.logger.info "[Redis] Connected to #{redis_url}"
  rescue Redis::BaseError => e
    # IMPORTANT: Do NOT raise — containers may start before Redis is ready
    Rails.logger.warn "[Redis] Connection not ready yet: #{e.class} - #{e.message}"
  end
end

# -------------------------------------------------------------------
# Runtime error monitoring (production only)
# -------------------------------------------------------------------

if Rails.env.production?
  ActiveSupport::Notifications.subscribe("redis.error") do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)
    Rails.logger.error "[Redis] Runtime error: #{event.payload[:error]}"

    # Optional error tracking
    Sentry.capture_exception(event.payload[:error]) if defined?(Sentry)
  end
end
