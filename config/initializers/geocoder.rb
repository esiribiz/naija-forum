# frozen_string_literal: true

# Geocoder Configuration
require "geocoder"

# Detect if we're in a build or precompile phase (no Redis should be attempted)
building_assets = ENV["SECRET_KEY_BASE_DUMMY"].present? || ENV["FLY_APP_NAME"].present? || Rails.env.development?

Geocoder.configure(
  # Geocoding options
  timeout: 5,                   # geocoding service timeout (seconds)
  lookup: :ipinfo,              # name of geocoding service (symbol)
  ip_lookup: :ipinfo,           # IP address geocoding service
  language: :en,                # ISO-639 language code
  use_https: true,              # use HTTPS for lookup requests
  ssl_verify: true,             # verify SSL
  http_headers: {},             # HTTP request headers

  # API key (from credentials or ENV)
  api_key: Rails.application.credentials.dig(:ipinfo, :api_key) || ENV["IPINFO_API_KEY"],

  # Cache configuration
  cache: -> {
    if building_assets
      # During build/precompile, skip Redis and use file cache
      Rails.logger.info "Geocoder: skipping Redis during build, using FileStore cache."
      ActiveSupport::Cache::FileStore.new(
        Rails.root.join("tmp/cache/geocoder"),
        expires_in: 24.hours
      )
    else
      begin
        redis = Redis.new(url: ENV["REDIS_URL"] || "redis://localhost:6379")
        redis.ping
        Rails.logger.info "Geocoder using Redis cache"
        redis
      rescue Redis::BaseError, SocketError, RuntimeError => e
        Rails.logger.warn "Redis unavailable for Geocoder cache: #{e.message}. Falling back to FileStore."
        ActiveSupport::Cache::FileStore.new(
          Rails.root.join("tmp/cache/geocoder"),
          expires_in: 24.hours
        )
      end
    end
  }.call,

  cache_options: {
    expiration: 24.hours,       # cache expiry
    prefix: "geocoder:"         # key prefix
  },

  # Restrict IPs from certain countries (optional)
  restricted_countries: ENV.fetch(
    "GEOCODER_RESTRICTED_COUNTRIES",
    "ZA,NG,EG,KE,ET,TZ,DZ,MA,SD,GH"
  ),

  # Exceptions that should raise errors
  always_raise: [
    Geocoder::OverQueryLimitError,
    Geocoder::RequestDenied,
    Geocoder::InvalidRequest,
    Geocoder::InvalidApiKey
  ],

  # Distance calculations
  units: :km,                   # :km for kilometers
  distances: :linear            # :linear is slightly faster than :spherical
)
