# frozen_string_literal: true

module RateLimitable
extend ActiveSupport::Concern

included do
    # Class level configurations
    class_attribute :rate_limit_configs, default: {}

    # Add Redis connection through redis-objects
    include Redis::Objects
end

class_methods do
    # Define a rate limit for a specific action
    # Example: rate_limit :login_attempts, limit: 5, period: 1.hour
    def rate_limit(action, limit:, period:)
    rate_limit_configs[action] = {
        limit: limit,
        period: period.to_i
    }

    # Define counter for the action
    counter "#{action}_counter", expireat: -> { (Time.now + period).to_i }
    end
end

# Instance methods

# Check if rate limit is exceeded for an action
def rate_limit_exceeded?(action)
    return false unless rate_limit_configs[action]

    count = get_attempts_count(action)
    count >= rate_limit_configs[action][:limit]
end

# Increment attempt counter for an action
def track_rate_limit_attempt!(action)
    validate_rate_limit_action!(action)

    counter = send("#{action}_counter")
    current_count = counter.increment

    if current_count >= rate_limit_configs[action][:limit]
    Rails.logger.warn(
        "[RateLimit] Limit exceeded for #{self.class.name}##{id} " \
        "action: #{action}, count: #{current_count}"
    )

    raise RateLimitExceeded.new(action: action, limit: rate_limit_configs[action][:limit])
    end

    current_count
end

# Get remaining attempts for an action
def remaining_attempts(action)
    validate_rate_limit_action!(action)

    config = rate_limit_configs[action]
    count = get_attempts_count(action)

    [0, config[:limit] - count].max
end

# Get time until rate limit reset
def time_until_reset(action)
    validate_rate_limit_action!(action)

    counter = send("#{action}_counter")
    counter.ttl
end

# Reset rate limit counter for an action
def reset_rate_limit!(action)
    validate_rate_limit_action!(action)

    counter = send("#{action}_counter")
    counter.reset
end

private

def get_attempts_count(action)
    counter = send("#{action}_counter")
    counter.value || 0
end

def validate_rate_limit_action!(action)
    unless rate_limit_configs[action]
    raise ArgumentError, "No rate limit configured for action: #{action}"
    end
end
end

class RateLimitExceeded < StandardError
attr_reader :action, :limit

def initialize(action:, limit:)
    @action = action
    @limit = limit
    super("Rate limit exceeded for action: #{action} (limit: #{limit})")
end
end
