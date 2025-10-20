# Geocoder Configuration
Geocoder.configure(
  # Geocoding options
  timeout: 5,
  lookup: :ipinfo,
  ip_lookup: :ipinfo,
  language: :en,
  use_https: true,
  ssl_verify: true,

  api_key: Rails.application.credentials.dig(:ipinfo, :api_key),

  # Cache: use FileStore (no Redis required)
  cache: ActiveSupport::Cache::FileStore.new(
    Rails.root.join("tmp/cache/geocoder"),
    expires_in: 24.hours
  ),
  cache_options: {
    expiration: 24.hours,
    prefix: "geocoder:"
  },

  # Calculation options
  units: :km,
  distances: :linear
)
