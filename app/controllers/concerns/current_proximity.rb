# frozen_string_literal: true

# Exposes the visitor's approximate location (from session) to controllers and views.
#
# The location is seeded by ProximityController after the browser grants
# navigator.geolocation. Without a seeded location, feed access is gated.
module CurrentProximity
  extend ActiveSupport::Concern

  Location = Data.define(:latitude, :longitude)

  RADIUS_CACHE_TTL = 30.minutes

  included do
    helper_method :current_proximity, :location_known?, :current_radius_km
  end

  def current_proximity
    return @current_proximity if defined?(@current_proximity)

    @current_proximity = build_current_proximity
  end

  def build_current_proximity
    return nil unless location_known?

    Location.new(
      latitude: session[:wall_lat].to_f,
      longitude: session[:wall_lng].to_f
    )
  end

  def location_known?
    session[:wall_lat].present? && session[:wall_lng].present?
  end

  def store_proximity(latitude:, longitude:)
    session[:wall_lat] = latitude.to_f
    session[:wall_lng] = longitude.to_f
    session.delete(:wall_radius_km)
    session.delete(:wall_radius_cached_at)
  end

  def clear_proximity
    session.delete(:wall_lat)
    session.delete(:wall_lng)
    session.delete(:wall_radius_km)
    session.delete(:wall_radius_cached_at)
  end

  def current_radius_km
    cached_at = session[:wall_radius_cached_at]
    return session[:wall_radius_km] if session[:wall_radius_km] && cached_at &&
                                       Time.zone.parse(cached_at) > RADIUS_CACHE_TTL.ago

    nil
  end

  def cache_radius_km(radius_km)
    session[:wall_radius_km] = radius_km
    session[:wall_radius_cached_at] = Time.current.iso8601
  end
end
