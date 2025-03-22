# frozen_string_literal: true

class IpGeolocationService
  class << self
    # Look up location data for an IP address
    # @param ip [String] The IP address to look up
    # @return [Hash] Location data including country, city, coordinates, etc.
    def lookup(ip)
      # Skip lookup for localhost/development IPs
      return empty_result if local_ip?(ip)
      
      # Use Geocoder to look up the IP
      result = Geocoder.search(ip).first
      
      return empty_result unless result
      
      {
        ip: ip,
        country: result.country,
        country_code: result.country_code,
        region: result.region,
        city: result.city,
        latitude: result.latitude,
        longitude: result.longitude,
        continent: get_continent(result.country_code),
        is_risky: risky_ip?(ip, result)
      }
    end
    
    # Check if an IP is from a restricted region
    # @param ip [String] The IP address to check
    # @return [Boolean] True if the IP is from a restricted region
    def restricted_region?(ip)
      data = lookup(ip)
      
      # List of restricted continents
      restricted_continents = ['africa']
      
      # List of additionally restricted countries (can be expanded)
      restricted_countries = [
        'RU', # Russia
        'KP'  # North Korea
      ]
      
      restricted_continents.include?(data[:continent]&.downcase) || 
        restricted_countries.include?(data[:country_code])
    end
    
    # Determine if an IP is considered risky based on various factors
    # @param ip [String] The IP address to check
    # @param result [Geocoder::Result] The geocoder result object
    # @return [Boolean] True if the IP is considered risky
    def risky_ip?(ip, result)
      return true if result.country_code == 'KP' # North Korea
      
      # Check for known proxy/VPN/Tor exit nodes (would require a proper database)
      # In a real implementation, this would check against a database of known
      # proxy/VPN/Tor exit nodes
      false
    end
    
    private
    
    # Check if an IP is a local/private IP address
    # @param ip [String] The IP address to check
    # @return [Boolean] True if the IP is a local/private IP
    def local_ip?(ip)
      ip == '127.0.0.1' || ip == '::1' || ip.start_with?('10.') || 
        ip.start_with?('172.16.') || ip.start_with?('192.168.')
    end
    
    # Return an empty result hash for cases where lookup isn't possible/needed
    # @return [Hash] Empty result hash
    def empty_result
      {
        ip: nil,
        country: nil,
        country_code: nil,
        region: nil,
        city: nil,
        latitude: nil,
        longitude: nil,
        continent: nil,
        is_risky: false
      }
    end
    
    # Get the continent for a country code
    # @param country_code [String] The country code
    # @return [String, nil] The continent name, or nil if unknown
    def get_continent(country_code)
      # This is a simplified mapping; a real implementation would be more complete
      continents = {
        'US' => 'North America',
        'CA' => 'North America',
        'MX' => 'North America',
        'BR' => 'South America',
        'AR' => 'South America',
        'GB' => 'Europe',
        'FR' => 'Europe',
        'DE' => 'Europe',
        'IT' => 'Europe',
        'ES' => 'Europe',
        'RU' => 'Europe',
        'CN' => 'Asia',
        'JP' => 'Asia',
        'IN' => 'Asia',
        'AU' => 'Oceania',
        'NZ' => 'Oceania',
        'ZA' => 'Africa',
        'EG' => 'Africa',
        'NG' => 'Africa'
      }
      
      continents[country_code] || begin
        # For country codes not in our mapping, try to determine continent
        # This is a simplified approach; a real implementation would have a complete mapping
        case country_code
        when /^(DZ|AO|BJ|BW|BF|BI|CV|CM|CF|TD|KM|CG|CD|DJ|EG|GQ|ER|SZ|ET|GA|GM|GH|GN|GW|CI|KE|LS|LR|LY|MG|MW|ML|MR|MU|MA|MZ|NA|NE|NG|RW|ST|SN|SC|SL|SO|ZA|SS|SD|TZ|TG|TN|UG|ZM|ZW)$/
          'Africa'
        when /^(AF|AM|AZ|BH|BD|BT|BN|KH|CN|CY|GE|HK|IN|ID|IR|IQ|IL|JP|JO|KZ|KW|KG|LA|LB|MO|MY|MV|MN|MM|NP|KP|OM|PK|PS|PH|QA|SA|SG|KR|LK|SY|TW|TJ|TH|TL|TR|TM|AE|UZ|VN|YE)$/
          'Asia'
        when /^(AL|AD|AT|BY|BE|BA|BG|HR|CZ|DK|EE|FO|FI|FR|DE|GI|GR|HU|IS|IE|IT|LV|LI|LT|LU|MK|MT|MD|MC|ME|NL|NO|PL|PT|RO|RU|SM|RS|SK|SI|ES|SE|CH|UA|GB|VA)$/
          'Europe'
        when /^(CA|US|MX|GT|BZ|SV|HN|NI|CR|PA)$/
          'North America'
        when /^(AR|BO|BR|CL|CO|EC|FK|GF|GY|PY|PE|SR|UY|VE)$/
          'South America'
        when /^(AU|FJ|KI|MH|FM|NR|NZ|PW|PG|WS|SB|TO|TV|VU)$/
          'Oceania'
        else
          nil
        end
      end
    end
  end
end

# frozen_string_literal: true

class IpGeolocationService
  # List of restricted regions - can be configured as needed
  RESTRICTED_REGIONS = {
    continents: ["Africa"],
    countries: ["North Korea", "Iran", "Syria", "Cuba"],
    # Add more specific restrictions as needed
  }.freeze

  # Lookup an IP address and return its location data
  # @param ip [String] The IP address to lookup
  # @return [Hash, nil] Location data or nil if not found
  def self.lookup(ip)
    return nil if ip.blank? || ip == "127.0.0.1" || ip == "::1"
    
    begin
      location = Geocoder.search(ip).first
      
      return nil unless location
      
      {
        ip: ip,
        country: location.country,
        country_code: location.country_code,
        continent: location.continent,
        region: location.region,
        city: location.city,
        latitude: location.latitude,
        longitude: location.longitude,
        timezone: location.timezone
      }
    rescue => e
      Rails.logger.error("IP Geolocation error for #{ip}: #{e.message}")
      nil
    end
  end

  # Check if an IP address is from a restricted region
  # @param ip [String] The IP address to check
  # @return [Boolean] True if the IP is from a restricted region
  def self.restricted?(ip)
    location_data = lookup(ip)
    return false unless location_data
    
    # Check if continent is restricted
    if RESTRICTED_REGIONS[:continents].include?(location_data[:continent])
      return true
    end
    
    # Check if country is restricted
    if RESTRICTED_REGIONS[:countries].include?(location_data[:country])
      return true
    end
    
    false
  end

  # Calculate distance between two logins (in kilometers)
  # @param location1 [Hash] First location with latitude and longitude
  # @param location2 [Hash] Second location with latitude and longitude
  # @return [Float, nil] Distance in kilometers or nil if coordinates missing
  def self.distance_between(location1, location2)
    return nil unless location1 && location2
    return nil unless location1[:latitude] && location1[:longitude] && 
                      location2[:latitude] && location2[:longitude]
    
    Geocoder::Calculations.distance_between(
      [location1[:latitude], location1[:longitude]],
      [location2[:latitude], location2[:longitude]],
      units: :km
    )
  end

  # Check if there's suspicious travel between login locations
  # @param previous_login [Hash] Previous login location data
  # @param current_login [Hash] Current login location data
  # @param time_difference_hours [Float] Time between logins in hours
  # @return [Boolean] True if travel appears suspicious
  def self.suspicious_travel?(previous_login, current_login, time_difference_hours)
    return false unless previous_login && current_login
    
    distance = distance_between(previous_login, current_login)
    return false unless distance
    
    # If distance is too large to travel in given time (assume max 800 km/hr by plane)
    # This is a very simplified check that could be enhanced
    max_possible_distance = time_difference_hours * 800
    
    distance > max_possible_distance
  end

  # Get the timezone offset for a location (in hours)
  # @param location_data [Hash] Location data with timezone
  # @return [Float, nil] Timezone offset in hours or nil if unavailable
  def self.timezone_offset(location_data)
    return nil unless location_data && location_data[:timezone]
    
    begin
      timezone = TZInfo::Timezone.get(location_data[:timezone])
      timezone.current_period.utc_offset / 3600.0
    rescue => e
      Rails.logger.error("Timezone error: #{e.message}")
      nil
    end
  end
  
  # Check if user is accessing from unusual hours based on their local time
  # @param location_data [Hash] Location data with timezone
  # @param access_time [Time] The time of access (defaults to current time)
  # @return [Boolean] True if accessing during unusual hours (2am-5am local time)
  def self.unusual_hours?(location_data, access_time = Time.current)
    offset = timezone_offset(location_data)
    return false unless offset
    
    local_hour = (access_time.utc.hour + offset) % 24
    local_hour >= 2 && local_hour < 5  # Unusual activity between 2am-5am local time
  end
end

