# frozen_string_literal: true

require 'connection_pool'

redis_config = {
url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
reconnect_attempts: 3,
connect_timeout: 5,
read_timeout: 5,
write_timeout: 5
}

# Use connection pooling for better performance
REDIS = ConnectionPool.new(size: ENV.fetch('REDIS_POOL_SIZE', 5).to_i, timeout: 5) do
Redis.new(redis_config)
end

# Configure redis-objects to use the connection pool
Redis::Objects.redis = REDIS

# Verify Redis connection on startup
begin
REDIS.with do |redis|
    redis.ping
end
Rails.logger.info "[Redis] Successfully connected to Redis server"
rescue Redis::CannotConnectError => e
Rails.logger.error "[Redis] Failed to connect to Redis server: #{e.message}"
raise
rescue Redis::ConnectionError => e
Rails.logger.error "[Redis] Connection error: #{e.message}"
raise
rescue Redis::TimeoutError => e
Rails.logger.error "[Redis] Timeout error: #{e.message}"
raise
rescue StandardError => e
Rails.logger.error "[Redis] Unexpected error: #{e.message}"
raise
end

# Monitor Redis connection in production
if Rails.env.production?
Rails.application.reloader.to_prepare do
    ActiveSupport::Notifications.subscribe('redis.error') do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)
    Rails.logger.error "[Redis] #{event.payload[:error]}"
    Bugsnag.notify(event.payload[:error]) if defined?(Bugsnag)
    end
end
end
