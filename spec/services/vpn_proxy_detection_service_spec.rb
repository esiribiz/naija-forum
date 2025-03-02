# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VpnProxyDetectionService do
  let(:service) { described_class.new }
  let(:normal_ip) { '1.2.3.4' }
  let(:vpn_ip) { '5.6.7.8' }
  let(:proxy_ip) { '9.10.11.12' }
  let(:tor_ip) { '13.14.15.16' }
  let(:private_ip) { '192.168.1.1' }
  let(:datacenter_ip) { '17.18.19.20' }

  before do
    # Mock Redis to avoid actual cache operations
    allow(Redis).to receive(:current).and_return(double('Redis').as_null_object)
    
    # Allow private_ip? to work with real IP addresses
    allow_any_instance_of(described_class).to receive(:private_ip?).and_return(false)
    allow_any_instance_of(described_class).to receive(:private_ip?).with(private_ip).and_return(true)
  end

  describe '#vpn_or_proxy?' do
    context 'with invalid or private IPs' do
      it 'returns false for nil IP' do
        expect(service.vpn_or_proxy?(nil)).to be false
      end

      it 'returns false for blank IP' do
        expect(service.vpn_or_proxy?('')).to be false
      end

      it 'returns false for private IP' do
        expect(service.vpn_or_proxy?(private_ip)).to be false
      end
    end

    context 'when result is cached' do
      it 'returns cached result' do
        mock_redis = double('Redis')
        allow(Redis).to receive(:current).and_return(mock_redis)
        allow(mock_redis).to receive(:get).with("vpn_proxy_check:#{normal_ip}").and_return('false')
        
        expect(service.vpn_or_proxy?(normal_ip)).to be false
      end
    end

    context 'with external API checks' do
      before do
        # Ensure cache miss
        allow(Redis.current).to receive(:get).and_return(nil)
        
        # Stub all detection methods to return false by default
        allow_any_instance_of(described_class).to receive(:check_external_apis).and_return(false)
        allow_any_instance_of(described_class).to receive(:check_tor_exit_node).and_return(false)
        allow_any_instance_of(described_class).to receive(:check_datacenter_ip).and_return(false)
        allow_any_instance_of(described_class).to receive(:check_hostname_patterns).and_return(false)
        allow_any_instance_of(described_class).to receive(:check_heuristics).and_return(false)
      end

      it 'detects VPN from external API' do
        allow_any_instance_of(described_class).to receive(:check_external_apis).with(vpn_ip).and_return(true)
        expect(service.vpn_or_proxy?(vpn_ip)).to be true
      end

      it 'detects Tor exit node' do
        allow_any_instance_of(described_class).to receive(:check_tor_exit_node).with(tor_ip).and_return(true)
        expect(service.vpn_or_proxy?(tor_ip)).to be true
      end

      it 'detects datacenter IP' do
        allow_any_instance_of(described_class).to receive(:check_datacenter_ip).with(datacenter_ip).and_return(true)
        expect(service.vpn_or_proxy?(datacenter_ip)).to be true
      end

      it 'returns false for normal IP' do
        expect(service.vpn_or_proxy?(normal_ip)).to be false
      end
    end

    context 'caching behavior' do
      let(:mock_redis) { double('Redis') }
      
      before do
        allow(Redis).to receive(:current).and_return(mock_redis)
        allow(mock_redis).to receive(:get).and_return(nil)
        allow_any_instance_of(described_class).to receive(:check_external_apis).with(vpn_ip).and_return(true)
      end
      
      it 'caches the result' do
        expect(mock_redis).to receive(:setex).with(
          "vpn_proxy_check:#{vpn_ip}",
          VpnProxyDetectionService::CACHE_EXPIRY[:vpn_result],
          'true'
        )
        
        service.vpn_or_proxy?(vpn_ip)
      end
    end
  end

  describe '#tor_exit_node?' do
    context 'with invalid or private IPs' do
      it 'returns false for nil IP' do
        expect(service.tor_exit_node?(nil)).to be false
      end

      it 'returns false for blank IP' do
        expect(service.tor_exit_node?('')).to be false
      end

      it 'returns false for private IP' do
        expect(service.tor_exit_node?(private_ip)).to be false
      end
    end

    context 'when result is cached' do
      it 'returns cached result' do
        mock_redis = double('Redis')
        allow(Redis).to receive(:current).and_return(mock_redis)
        allow(mock_redis).to receive(:get).with("tor_exit_node:#{tor_ip}").and_return('true')
        
        expect(service.tor_exit_node?(tor_ip)).to be true
      end
    end

    context 'with Tor exit node check' do
      before do
        # Ensure cache miss
        allow(Redis.current).to receive(:get).and_return(nil)
      end

      it 'detects Tor exit node' do
        allow_any_instance_of(described_class).to receive(:check_tor_exit_node).with(tor_ip).and_return(true)
        expect(service.tor_exit_node?(tor_ip)).to be true
      end

      it 'returns false for normal IP' do
        allow_any_instance_of(described_class).to receive(:check_tor_exit_node).with(normal_ip).and_return(false)
        expect(service.tor_exit_node?(normal_ip)).to be false
      end
    end

    context 'caching behavior' do
      let(:mock_redis) { double('Redis') }
      
      before do
        allow(Redis).to receive(:current).and_return(mock_redis)
        allow(mock_redis).to receive(:get).and_return(nil)
        allow_any_instance_of(described_class).to receive(:check_tor_exit_node).with(tor_ip).and_return(true)
      end
      
      it 'caches the result' do
        expect(mock_redis).to receive(:setex).with(
          "tor_exit_node:#{tor_ip}",
          VpnProxyDetectionService::CACHE_EXPIRY[:tor_result],
          'true'
        )
        
        service.tor_exit_node?(tor_ip)
      end
    end
  end

  describe '#proxy?' do
    context 'with invalid or private IPs' do
      it 'returns false for nil IP' do
        expect(service.proxy?(nil)).to be false
      end

      it 'returns false for blank IP' do
        expect(service.proxy?('')).to be false
      end

      it 'returns false for private IP' do
        expect(service.proxy?(private_ip)).to be false
      end
    end

    context 'when result is cached' do
      it 'returns cached result' do
        mock_redis = double('Redis')
        allow(Redis).to receive(:current).and_return(mock_redis)
        allow(mock_redis).to receive(:get).with("proxy_check:#{proxy_ip}").and_return('true')
        
        expect(service.proxy?(proxy_ip)).to be true
      end
    end

    context 'with proxy checks' do
      before do
        # Ensure cache miss
        allow(Redis.current).to receive(:get).and_return(nil)
        
        # Stub detection methods
        allow_any_instance_of(described_class).to receive(:check_open_proxy).and_return(false)
        allow_any_instance_of(described_class).to receive(:suspicious_proxy_heuristics).and_return(false)
      end

      it 'detects open proxy' do
        allow_any_instance_of(described_class).to receive(:check_open_proxy).with(proxy_ip).and_return(true)
        expect(service.proxy?(proxy_ip)).to be true
      end

      it 'detects proxy by heuristics' do
        allow_any_instance_of(described_class).to receive(:suspicious_proxy_heuristics).with(proxy_ip).and_return(true)
        expect(service.proxy?(proxy_ip)).to be true
      end

      it 'returns false for normal IP' do
        expect(service.proxy?(normal_ip)).to be false
      end
    end

    context 'caching behavior' do
      let(:mock_redis) { double('Redis') }
      
      before do
        allow(Redis).to receive(:current).and_return(mock_redis)
        allow(mock_redis).to receive(:get).and_return(nil)
        allow_any_instance_of(described_class).to receive(:check_open_proxy).with(proxy_ip).and_return(true)
      end
      
      it 'caches the result' do
        expect(mock_redis).to receive(:setex).with(
          "proxy_check:#{proxy_ip}",
          VpnProxyDetectionService::CACHE_EXPIRY[:proxy_result],
          'true'
        )
        
        service.proxy?(proxy_ip)
      end
    end
  end

  describe '.flush_cache' do
    it 'flushes all caches' do
      mock_redis = double('Redis')
      allow(Redis).to receive(:current).and_return(mock_redis)
      
      expect(mock_redis).to receive(:keys).with("vpn_proxy_check:*").and_return(["vpn_proxy_check:1.2.3.4"])
      expect(mock_redis).to receive(:keys).with("tor_exit_node:*").and_return(["tor_exit_node:5.6.7.8"])
      expect(mock_redis).to receive(:keys).with("proxy_check:*").and_return(["proxy_check:9.10.11.12"])
      
      expect(mock_redis).to receive(:del).with("vpn_proxy_check:1.2.3.4")
      expect(mock_redis).to receive(:del).with("tor_exit_node:5.6.7.8")
      expect(mock_redis).to receive(:del).with("proxy_check:9.10.11.12")
      
      expect(described_class.flush_cache).to be true
    end
  end

  describe 'private methods' do
    # We test a few critical private methods to ensure they work as expected
    
    describe '#check_tor_exit_node' do
      let(:tor_exit_list) { "# Tor exit node list\n13.14.15.16\n21.22.23.24" }
      
      before do
        # Stub the HTTP request to the Tor exit list
        stub_request(:get, "https://check.torproject.org/torbulkexitlist").
          to_return(status: 200, body: tor_exit_list)
      end
      
      it 'detects IP in Tor exit list' do
        expect(service.send(:check_tor_exit_node, tor_ip)).to be true
      end
      
      it 'returns false for IP not in Tor exit list' do
        expect(service.send(:check_tor_exit_node, normal_ip)).to be false
      end
      
      it 'handles errors gracefully' do
        stub_request(:get, "https://check.torproject.org/torbulkexitlist").
          to_return(status: 500)
        
        expect(service.send(:check_tor_exit_node, tor_ip)).to be false
      end
    end
    
    describe '#check_datacenter_ip' do
      let(:datacenter_location_data) do
        {
          "country" => "US",
          "city" => "Seattle",
          "timezone" => "America/Los_Angeles",
          "latitude" => 47.6062,
          "longitude" => -122.3331,
          "asn" => "AS16509", # AWS - in VPN_PROXY_ASNS list
          "organization" => "Amazon.com, Inc.",
          "isp" => "Amazon AWS"
        }
      end
      
      let(:normal_location_data) do
        {
          "country" => "US",
          "city" => "Chicago",
          "timezone" => "America/Chicago",
          "latitude" => 41.8781,
          "longitude" => -87.6298,
          "asn" => "AS7018", # AT&T - not in VPN_PROXY_ASNS list
          "organization" => "AT&T Services, Inc.",
          "isp" => "AT&T U-verse"
        }
      end
      
      it 'detects datacenter IP by ASN' do
        allow_any_instance_of(described_class).to receive(:get_ip_location_data).
          with(datacenter_ip).and_return(datacenter_location_data)
        
        expect(service.send(:check_datacenter_ip, datacenter_ip)).to be true
      end
      
      it 'returns false for normal IP' do
        allow_any_instance_of(described_class).to receive(:get_ip_location_data).
          with(normal_ip).and_return(normal_location_data)
        
        expect(service.send(:check_datacenter_ip, normal_ip)).to be false
      end
    end
    
    describe '#check_hostname_patterns' do
      it 'detects VPN hostname' do
        allow(Resolv).to receive(:getname).with(vpn_ip).and_return('vpn-server.example.com')
        expect(service.send(:check_hostname_patterns, vpn_ip)).to be true
      end
      
      it 'detects proxy hostname' do
        allow(Resolv).to receive(:getname).with(proxy_ip).and_return('proxy.example.com')
        expect(service.send(:check_hostname_patterns, proxy_ip)).to be true
      end
      
      it 'returns false for normal hostname' do
        allow(Resolv).to receive(:getname).with(normal_ip).and_return('server.example.com')
        expect(service.send(:check_hostname_patterns

