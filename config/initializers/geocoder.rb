# Geocoder Configuration
Geocoder.configure(
  # Geocoding options
  timeout: 5,                   # geocoding service timeout (seconds)
  lookup: :ipinfo,              # name of geocoding service (symbol)
  ip_lookup: :ipinfo,           # name of IP address geocoding service (symbol)
  language: :en,                # ISO-639 language code
  use_https: true,              # use HTTPS for lookup requests? (if supported)
  ssl_verify: true,             # use HTTPS with SSL verification
  http_headers: { },            # HTTP request headers
  
  # API keys for geocoding services (configure in credentials.yml or environment variables)
  api_key: Rails.application.credentials.dig(:ipinfo, :api_key),

  # Cache configuration
  # Try to use Redis for caching, fall back to file store if Redis is unavailable
  cache: -> {
    begin
      # Try to connect to Redis first
      redis = Redis.new
      # Test the connection with a simple ping
      redis.ping
      Rails.logger.info "Geocoder using Redis cache"
      redis
    rescue Redis::BaseError, SocketError, RuntimeError => e
      # If Redis fails, fall back to ActiveSupport::Cache::FileStore
      Rails.logger.warn "Redis unavailable for Geocoder cache: #{e.message}. Falling back to file store."
      ActiveSupport::Cache::FileStore.new(
        Rails.root.join("tmp/cache/geocoder"),
        { expires_in: 24.hours }
      )
    end
  }.call,
  cache_options: {
    expiration: 24.hours,       # expiration time in seconds
    prefix: "geocoder:"         # prefix (string) to use for all cache keys
  },

  # IP address restriction options
  # Comma-separated list of ISO country codes that are considered restricted regions
  # For example, countries in Africa: ZA,NG,EG,KE,ET,TZ,DZ,MA,SD,GH
  restricted_countries: ENV.fetch('GEOCODER_RESTRICTED_COUNTRIES', 'ZA,NG,EG,KE,ET,TZ,DZ,MA,SD,GH'),

  # Exceptions that can be raised
  always_raise: [
    Geocoder::OverQueryLimitError,
    Geocoder::RequestDenied,
    Geocoder::InvalidRequest,
    Geocoder::InvalidApiKey
  ],

  # Calculation options
  units: :km,                   # :km for kilometers or :mi for miles
  distances: :linear            # :spherical or :linear
)

