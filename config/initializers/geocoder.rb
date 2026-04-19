# frozen_string_literal: true

Geocoder.configure(
  # IP lookup service. ipinfo_io requires no API key for the basic tier (~50k req/day).
  # For higher volume swap to :maxmind_local (offline database) or :ipstack with an API key.
  ip_lookup: :ipinfo_io,

  # Hard timeout so a slow geocoder call never blocks a request for long.
  timeout: 3,

  # Cache results in Rails.cache to avoid repeated external calls for the same IP.
  cache: Rails.cache,
  cache_prefix: "geocoder:",
  cache_expires_in: 1.day,

  # Always use HTTPS for external lookup requests.
  use_https: true
)
