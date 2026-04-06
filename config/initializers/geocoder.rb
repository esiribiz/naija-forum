# Geocoder Configuration
Geocoder.configure(
  timeout: 5,
  lookup: :ipinfo,
  ip_lookup: :ipinfo,
  language: :en,
  use_https: true,
  ssl_verify: true,

  api_key: (
    if ENV["SECRET_KEY_BASE"] != "dummy"
      Rails.application.credentials.dig(:ipinfo, :api_key)
    end
  ),

  cache: ActiveSupport::Cache::FileStore.new(
    Rails.root.join("tmp/cache/geocoder"),
    expires_in: 24.hours
  ),
  cache_options: {
    expiration: 24.hours,
    prefix: "geocoder:"
  },

  units: :km,
  distances: :linear
)
