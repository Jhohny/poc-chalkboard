# frozen_string_literal: true

# Proximity querying, privacy fuzzing, and distance helpers for posts.
#
# Fuzzing has two layers:
#   - session-stable offset  (same offset for every post in a session)
#   - per-post jitter        (tiny additional randomness so repeated posts
#                             from one session don't colocate exactly)
module Proximity
  extend ActiveSupport::Concern

  EARTH_RADIUS_KM = 6371.0
  FUZZ_DEGREES = 0.005
  JITTER_DEGREES = 0.001
  RADIUS_TIERS_KM = [3, 8, 15, 25, 50].freeze
  MIN_BATCH = 5
  MAX_RADIUS_KM = 50

  # Haversine distance in kilometres. Lat/lng come in as bind parameters so
  # this stays safe to use with `sanitize_sql_array`.
  DISTANCE_SQL = <<~SQL.squish.freeze
    (#{EARTH_RADIUS_KM} * acos(least(1.0,
      cos(radians(?)) * cos(radians(latitude)) *
      cos(radians(longitude) - radians(?)) +
      sin(radians(?)) * sin(radians(latitude))
    )))
  SQL

  included do
    scope :within_km, lambda { |lat, lng, radius_km|
      lat_f = lat.to_f
      lng_f = lng.to_f
      r_f   = radius_km.to_f

      selection = sanitize_sql_array(["#{table_name}.*, #{DISTANCE_SQL} AS distance_km",
                                      lat_f, lng_f, lat_f])
      condition = sanitize_sql_array(["#{DISTANCE_SQL} <= ?",
                                      lat_f, lng_f, lat_f, r_f])

      select(Arel.sql(selection)).where(Arel.sql(condition))
    }
  end

  class_methods do
    def tier_for(distance_km)
      RADIUS_TIERS_KM.find { |tier| distance_km <= tier } || MAX_RADIUS_KM
    end

    def choose_radius(distances)
      RADIUS_TIERS_KM.find do |tier|
        distances.count { |d| d <= tier } >= MIN_BATCH
      end || MAX_RADIUS_KM
    end

    def session_offset(session_token)
      digest = Digest::SHA256.hexdigest(session_token.to_s)
      parts = digest.scan(/.{8}/).first(2)
      parts.map do |hex|
        fraction = hex.to_i(16).to_f / 0xffffffff
        (fraction - 0.5) * 2 * FUZZ_DEGREES
      end
    end
  end

  def apply_proximity_fuzz(raw_lat, raw_lng, session_token)
    offset_lat, offset_lng = self.class.session_offset(session_token)
    self.latitude  = (raw_lat.to_f + offset_lat + jitter).round(6)
    self.longitude = (raw_lng.to_f + offset_lng + jitter).round(6)
  end

  def distance_to(lat, lng)
    return read_attribute(:distance_km) if has_attribute?(:distance_km)

    haversine(latitude.to_f, longitude.to_f, lat.to_f, lng.to_f)
  end

  private

  def jitter
    rand(-JITTER_DEGREES..JITTER_DEGREES)
  end

  def haversine(lat1, lng1, lat2, lng2)
    rad = ->(d) { d * Math::PI / 180 }
    dlat = rad.call(lat2 - lat1)
    dlng = rad.call(lng2 - lng1)
    a = (Math.sin(dlat / 2)**2) +
        (Math.cos(rad.call(lat1)) * Math.cos(rad.call(lat2)) *
        (Math.sin(dlng / 2)**2))
    Proximity::EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
  end
end
