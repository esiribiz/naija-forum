class LoginActivity < ApplicationRecord
  belongs_to :user

  # Store login information
  validates :ip_address, presence: true
  validates :user_agent, presence: true
  validates :login_at, presence: true

  # Optional fields for location data if IP is resolved
  attribute :country
  attribute :city
  attribute :region
  attribute :latitude
  attribute :longitude

  # Callback to resolve location data when created
  after_create :resolve_location_data

  # Track success/failure
  attribute :success, :boolean, default: true

  # Additional info like device type, browser, etc. can be extracted from user_agent
  def browser
    user_agent&.split(" ").first
  end

  # Scopes for easier querying
  scope :successful, -> { where(success: true) }
  scope :failed, -> { where(success: false) }
  scope :recent, -> { order(login_at: :desc) }

  # Get most recent login activity for a user
  def self.most_recent_for(user)
    where(user: user).successful.recent.first
  end

  # Check if this login is from a restricted location
  def from_restricted_location?
    return false if country.blank?

    # List of restricted regions/countries
    restricted_regions = [
      # African countries
      "Nigeria", "Ghana", "Kenya", "South Africa", "Egypt",
      "Morocco", "Algeria", "Tunisia", "Uganda", "Tanzania",
      "Ethiopia", "Angola", "Zimbabwe", "Zambia", "Cameroon",
      "Democratic Republic of the Congo", "Rwanda", "Mali",
      "Senegal", "Ivory Coast", "Guinea", "Benin", "Niger",
      "Burkina Faso", "Togo", "Sudan", "South Sudan", "Libya",
      "Somalia", "Malawi", "Mozambique", "Namibia", "Botswana",
      "Madagascar", "Mauritius", "Seychelles", "Liberia",
      "Sierra Leone", "Gambia", "Gabon", "Congo", "Chad",
      "Central African Republic", "Equatorial Guinea", "Eritrea",
      "Djibouti", "Burundi", "Lesotho", "Swaziland", "Cape Verde",
      "Comoros", "Mauritania", "Western Sahara"
      # Add other restricted regions as needed
    ]

    restricted_regions.include?(country)
  end

  # Check if there's a suspicious pattern of logins
  def suspicious_pattern?
    return false unless user

    recent_activities = user.login_activities.recent.limit(5)
    return false if recent_activities.count < 3

    # Check if this login is from a very different location compared to recent logins
    if recent_activities.any? && latitude.present? && longitude.present?
      different_location_count = 0

      recent_activities.each do |activity|
        next if activity.id == id
        next unless activity.latitude.present? && activity.longitude.present?

        # Calculate rough distance using lat/long
        distance = calculate_distance(
          latitude, longitude,
          activity.latitude, activity.longitude
        )

        # If distance is greater than 500km, consider it suspicious
        different_location_count += 1 if distance > 500
      end

      # If more than 2 logins are from significantly different locations, flag as suspicious
      return true if different_location_count >= 2
    end

    # Check for rapid logins from different locations
    if recent_activities.count >= 3
      # If 3 different countries in the last 5 logins, flag as suspicious
      countries = recent_activities.map(&:country).compact.uniq
      return true if countries.length >= 3
    end

    false
  end

  private

  # Resolve location data using the IP Geolocation Service
  def resolve_location_data
    return if ip_address.blank?

    begin
      location_data = IpGeolocationService.lookup(ip_address)

      if location_data
        self.country = location_data[:country]
        self.city = location_data[:city]
        self.region = location_data[:region]
        self.latitude = location_data[:latitude]
        self.longitude = location_data[:longitude]

        # Save the resolved location data
        save if changed?
      end
    rescue => e
      # Log error but don't prevent login
      Rails.logger.error("Error resolving location for IP #{ip_address}: #{e.message}")
    end
  end

  # Simple Haversine formula to calculate distance between two points
  def calculate_distance(lat1, lon1, lat2, lon2)
    radius = 6371 # Earth's radius in km

    dlat = (lat2 - lat1) * Math::PI / 180
    dlon = (lon2 - lon1) * Math::PI / 180

    a = Math.sin(dlat/2) * Math.sin(dlat/2) +
        Math.cos(lat1 * Math::PI / 180) * Math.cos(lat2 * Math::PI / 180) *
        Math.sin(dlon/2) * Math.sin(dlon/2)

    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
    distance = radius * c

    return distance
  end
end
