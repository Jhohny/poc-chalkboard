# frozen_string_literal: true

# Determines the visitor's city from the current request.
#
# Priority chain:
#   1. Dev session override  – Rails.env.development? + session[:dev_city_override]
#   2. Dev localhost fallback – Rails.env.development? + loopback IP + LOCAL_CITY_FALLBACK env var
#   3. CF-IPCity header       – set by Cloudflare on every proxied request (production)
#   4. Geocoder IP lookup     – server-side fallback when not behind Cloudflare
#
# Call via:
#   CityLocator.call(request, dev_override: session[:dev_city_override])
#
class CityLocator
  City = Data.define(:name, :slug) do
    def stream_name
      "city_wall:#{slug}"
    end
  end

  LOCAL_IPS       = %w[127.0.0.1 ::1].freeze
  CF_CITY_HEADER  = "HTTP_CF_IPCITY"

  def self.call(request, dev_override: nil)
    new(request, dev_override: dev_override).detect
  end

  def initialize(request, dev_override: nil)
    @request      = request
    @dev_override = dev_override
  end

  def detect
    name = dev_session_override ||
           dev_localhost_fallback ||
           app_city_header ||
           cloudflare_city ||
           geocoded_city

    name = normalize(name)
    return if name.blank?

    City.new(name: name, slug: name.parameterize)
  end

  private

  attr_reader :request, :dev_override

  # 1. Session-based city override — development only.
  #    Set by visiting /?dev_city=Los+Angeles in the browser.
  def dev_session_override
    return unless Rails.env.development?

    dev_override.presence
  end

  # 2. Localhost fallback — development only.
  #    Controlled by LOCAL_CITY_FALLBACK env var; defaults to San Francisco.
  def dev_localhost_fallback
    return unless Rails.env.development?
    return unless LOCAL_IPS.include?(request.remote_ip)

    ENV.fetch("LOCAL_CITY_FALLBACK", "San Francisco")
  end

  # 3. X-App-City header — used in tests and internal tooling to explicitly set a city.
  def app_city_header
    request.get_header("HTTP_X_APP_CITY").presence
  end

  # 4. Cloudflare CF-IPCity header — most reliable source in production.
  #    cloudflare-rails ensures request.remote_ip is the real visitor IP,
  #    and CF-IPCity is the city Cloudflare resolved from that IP.
  def cloudflare_city
    request.get_header(CF_CITY_HEADER).presence
  end

  # 4. Geocoder server-side lookup — fallback for staging / non-CF environments.
  #    Result is cached in Rails.cache (see config/initializers/geocoder.rb).
  #    Skipped for local/private IPs to avoid meaningless lookups.
  def geocoded_city
    ip = request.remote_ip
    return if LOCAL_IPS.include?(ip)

    Geocoder.search(ip).first&.city.presence
  rescue StandardError
    nil
  end

  def normalize(city_name)
    city_name.to_s.squish.presence
  end
end
