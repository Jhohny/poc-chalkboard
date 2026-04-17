# frozen_string_literal: true

# Best-effort city detection for the current request.
class CityLocator
  City = Data.define(:name, :slug) do
    def stream_name
      "city_wall:#{slug}"
    end
  end

  HEADER_KEYS = %w[
    HTTP_X_APP_CITY
    HTTP_FLY_REGION_CITY
    HTTP_CF_IPCITY
    HTTP_X_CITY
    HTTP_X_GEO_CITY
  ].freeze

  LOCAL_IPS = ['127.0.0.1', '::1'].freeze

  def self.call(request)
    city_name = location_city(request)
    city_name ||= forwarded_city(request)
    city_name ||= local_city_fallback(request)
    city_name = normalize(city_name)

    return if city_name.blank?

    City.new(name: city_name, slug: city_name.parameterize)
  end

  def self.location_city(request)
    return unless request.respond_to?(:location)

    request.location&.city
  rescue StandardError
    nil
  end

  def self.forwarded_city(request)
    HEADER_KEYS.filter_map { |header| request.get_header(header).presence }.first
  end

  def self.local_city_fallback(request)
    return unless Rails.env.development?
    return unless LOCAL_IPS.include?(request.remote_ip)

    ENV.fetch('LOCAL_CITY_FALLBACK', 'San Francisco')
  end

  def self.normalize(city_name)
    city_name.to_s.squish.presence
  end
  private_class_method :location_city, :forwarded_city, :local_city_fallback, :normalize
end
