# frozen_string_literal: true

require 'net/http'
require 'json'
require 'digest'

# Service to detect if an IP address is from a VPN, proxy, or Tor network
class VpnProxyDetectionService
  # Redis cache expiration times (in seconds)
  CACHE_EXPIRY = {
    vpn_result: 1.day.to_i,
    tor_result: 12.hours.to_i,
    proxy_result: 6.hours.to_i
  }.freeze

  # List of common VPN/proxy provider ASNs (Autonomous System Numbers)
  VPN_PROXY_ASNS = [
    'AS9009',  # M247 Ltd
    'AS16276', # OVH
    'AS16509', # Amazon AWS
    'AS14061', # DigitalOcean
    'AS20473', # Choopa/Vultr
    'AS3842',  # RAMNODE
    'AS30633', # Leaseweb USA
    'AS51167', # Contabo
    'AS174',   # Cogent Communications
    'AS24940', # Hetzner
    'AS46606', # Unified Layer
    'AS36352', # ColoCrossing
    'AS55293'  # A2 Hosting
  ].freeze

  # Common ports used by proxies
  PROXY_PORTS = [80, 443, 808, 1080, 3128, 8080, 8888, 9999].freeze

  # Initialize with optional API keys
  def initialize(ip_quality_score_api_key: nil, proxy_check_api_key: nil)
    @ip_quality_score_api_key = ip_quality_score_api_key || ENV['IP_QUALITY_SCORE_API_KEY']
    @proxy_check_api_key = proxy_check_api_key || ENV['PROXY_CHECK_API_KEY']
  end

  # Main method to check if an IP is from a VPN, proxy, or Tor
  def vpn_or_proxy?(ip_address)
    return false if ip_address.blank? || private_ip?(ip_address)
    
    # Try to get from cache first
    cache_key = "vpn_proxy_check:#{ip_address}"
    cached_result = Redis.current.get(cache_key)
    return ActiveModel::Type::Boolean.new.cast(cached_result) unless cached_result.nil?
    
    # Perform checks
    result = check_external_apis(ip_address) || 
             check_tor_exit_node(ip_address) || 
             check_datacenter_ip(ip_address) || 
             check_hostname_patterns(ip_address) ||
             check_heuristics(ip_address)
    
    # Cache the result
    Redis.current.setex(cache_key, CACHE_EXPIRY[:vpn_result], result.to_s)
    
    result
  end

  # Checks if IP is a Tor exit node
  def tor_exit_node?(ip_address)
    return false if ip_address.blank? || private_ip?(ip_address)
    
    # Try to get from cache first
    cache_key = "tor_exit_node:#{ip_address}"
    cached_result = Redis.current.get(cache_key)
    return ActiveModel::Type::Boolean.new.cast(cached_result) unless cached_result.nil?
    
    result = check_tor_exit_node(ip_address)
    
    # Cache the result
    Redis.current.setex(cache_key, CACHE_EXPIRY[:tor_result], result.to_s)
    
    result
  end

  # Check if IP is likely a proxy
  def proxy?(ip_address)
    return false if ip_address.blank? || private_ip?(ip_address)
    
    # Try to get from cache first
    cache_key = "proxy_check:#{ip_address}"
    cached_result = Redis.current.get(cache_key)
    return ActiveModel::Type::Boolean.new.cast(cached_result) unless cached_result.nil?
    
    # A proxy is likely if it's an open proxy or has proxy-like characteristics
    result = check_open_proxy(ip_address) || suspicious_proxy_heuristics(ip_address)
    
    # Cache the result
    Redis.current.setex(cache_key, CACHE_EXPIRY[:proxy_result], result.to_s)
    
    result
  end

  # Cleanup method to flush all caches
  def self.flush_cache
    Redis.current.keys("vpn_proxy_check:*").each { |key| Redis.current.del(key) }
    Redis.current.keys("tor_exit_node:*").each { |key| Redis.current.del(key) }
    Redis.current.keys("proxy_check:*").each { |key| Redis.current.del(key) }
    true
  end

  private

  # Check if the IP address is a private (non-routable) IP
  def private_ip?(ip_address)
    ip = IPAddr.new(ip_address) rescue nil
    return true if ip.nil?
    
    ip.private? || ip.loopback?
  end

  # Check against external APIs
  def check_external_apis(ip_address)
    return true if check_ip_quality_score(ip_address)
    return true if check_proxy_check_io(ip_address)
    false
  end

  # Check IP against IPQualityScore API
  def check_ip_quality_score(ip_address)
    return false unless @ip_quality_score_api_key.present?
    
    begin
      url = "https://ipqualityscore.com/api/json/ip/#{@ip_quality_score_api_key}/#{ip_address}"
      response = http_get(url)
      
      return false unless response && response["success"]
      
      # Consider it a proxy/VPN if it's explicitly marked as such or has a high fraud score
      response["proxy"] || response["vpn"] || response["tor"] || 
        (response["fraud_score"] && response["fraud_score"] > 85)
    rescue => e
      Rails.logger.error("IPQualityScore API error: #{e.message}")
      false
    end
  end

  # Check IP against ProxyCheck.io API
  def check_proxy_check_io(ip_address)
    return false unless @proxy_check_api_key.present?
    
    begin
      url = "https://proxycheck.io/v2/#{ip_address}?key=#{@proxy_check_api_key}&vpn=1&risk=1"
      response = http_get(url)
      
      return false unless response && response["status"] == "ok" && response[ip_address]
      
      ip_data = response[ip_address]
      # Consider it a proxy/VPN if it's explicitly marked as such or has a high risk score
      ip_data["proxy"] == "yes" || ip_data["type"] == "VPN" || 
        (ip_data["risk"] && ip_data["risk"].to_i > 75)
    rescue => e
      Rails.logger.error("ProxyCheck.io API error: #{e.message}")
      false
    end
  end

  # Check if the IP is a Tor exit node
  def check_tor_exit_node(ip_address)
    begin
      # Check against the Tor Project's list of exit nodes
      url = "https://check.torproject.org/torbulkexitlist"
      response = Net::HTTP.get(URI(url)) rescue nil
      
      return false unless response
      
      # The list is just a plain text file with one IP per line
      tor_exit_nodes = response.split("\n").reject { |line| line.start_with?('#') }
      tor_exit_nodes.include?(ip_address)
    rescue => e
      Rails.logger.error("Tor exit node check error: #{e.message}")
      false
    end
  end

  # Check if the IP belongs to a known datacenter/cloud provider
  def check_datacenter_ip(ip_address)
    location_data = get_ip_location_data(ip_address)
    return false unless location_data
    
    # Check ASN against known VPN/proxy providers
    if location_data["asn"]
      return true if VPN_PROXY_ASNS.include?(location_data["asn"])
    end
    
    # Check organization/ISP against known VPN keywords
    if location_data["organization"] || location_data["isp"]
      org = (location_data["organization"] || location_data["isp"] || "").downcase
      vpn_keywords = ["vpn", "proxy", "hosting", "cloud", "server", "dedicated", "virtual"]
      return true if vpn_keywords.any? { |keyword| org.include?(keyword) }
    end
    
    false
  end

  # Check hostname patterns associated with VPNs/proxies
  def check_hostname_patterns(ip_address)
    begin
      hostname = Resolv.getname(ip_address) rescue nil
      return false unless hostname
      
      # Check for common VPN/proxy hostname patterns
      vpn_patterns = [
        /vpn/i, /proxy/i, /tor/i, /tunnel/i, /exit/i, /relay/i, /hosted/i, /cloud/i,
        /dedi/i, /vps/i, /virtual/i, /anon/i, /hide/i, /mask/i, /secure/i
      ]
      
      return true if vpn_patterns.any? { |pattern| hostname =~ pattern }
      false
    rescue => e
      Rails.logger.error("Hostname pattern check error: #{e.message}")
      false
    end
  end

  # Check if the IP is an open proxy by scanning common proxy ports
  def check_open_proxy(ip_address)
    # This is a simplified implementation - in production, you might
    # want to use a background job for port scanning or a dedicated service
    PROXY_PORTS.any? do |port|
      begin
        Socket.tcp(ip_address, port, connect_timeout: 2) { |sock| sock.close; true }
      rescue
        false
      end
    end
  end

  # Perform heuristic checks for VPN/proxy characteristics
  def check_heuristics(ip_address)
    # Check for geolocation inconsistencies
    geo_data = get_ip_location_data(ip_address)
    return false unless geo_data
    
    # Suspicious if country doesn't match timezone
    if geo_data["country"] && geo_data["timezone"]
      country_code = geo_data["country"].upcase
      timezone = geo_data["timezone"]
      
      # Very simplified timezone check - in production you'd want a more robust mapping
      expected_regions = {
        "US" => ["America/", "US/"],
        "GB" => ["Europe/London"],
        "DE" => ["Europe/Berlin"],
        "FR" => ["Europe/Paris"],
        "AU" => ["Australia/"]
      }
      
      if expected_regions[country_code] && 
         expected_regions[country_code].none? { |r| timezone.include?(r) }
        return true
      end
    end
    
    false
  end

  # Additional heuristics specifically for proxy detection
  def suspicious_proxy_heuristics(ip_address)
    # Check if IP has abnormal connection characteristics
    # This would include checks like:
    # - Unusually high number of HTTP headers
    # - Presence of specific proxy headers
    # - Connection speed inconsistencies
    
    # In a real implementation, these might come from web server logs
    # or other data sources. For this example, we'll return false.
    false
  end

  # Get IP location data using Geocoder
  def get_ip_location_data(ip_address)
    begin
      location = Geocoder.search(ip_address).first
      return {} unless location
      
      # Extract relevant data
      {
        "country" => location.country_code,
        "city" => location.city,
        "timezone" => location.timezone,
        "latitude" => location.latitude,
        "longitude" => location.longitude,
        "asn" => location.data["asn"],
        "organization" => location.data["organization"],
        "isp" => location.data["isp"]
      }
    rescue => e
      Rails.logger.error("Geolocation error: #{e.message}")
      nil
    end
  end

  # Helper method for making HTTP GET requests
  def http_get(url)
    uri = URI(url)
    response = Net::HTTP.get_response(uri)
    
    return nil unless response.is_a?(Net::HTTPSuccess)
    
    JSON.parse(response.body)
  rescue => e
    Rails.logger.error("HTTP GET error for #{url}: #{e.message}")
    nil
  end
end

