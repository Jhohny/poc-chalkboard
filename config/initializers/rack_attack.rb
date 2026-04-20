# frozen_string_literal: true

# IP-based rate limiting on the mutation endpoints.
#
# The per-session rate limit in Post#respect_rate_limit protects against a
# single browser flooding the feed; this layer protects against an attacker
# rotating session cookies to bypass it. Reads are intentionally left
# unthrottled so the feed stays snappy.
#
# Limits are generous on purpose. Tighten them after observing real traffic.

module Rack
  # Rate-limiting configuration (Rack::Attack is reopened here, not defined).
  class Attack
    # Stash state in the same cache Rails uses for everything else.
    # SolidCache is durable, so counters survive a reboot — which is what
    # we want (an attacker shouldn't get a free minute of budget after a
    # deploy).
    Rack::Attack.cache.store = Rails.cache

    throttle('posts/create/ip', limit: 10, period: 1.minute) do |request|
      request.ip if request.post? && request.path == '/posts'
    end

    throttle('proximity/create/ip', limit: 20, period: 1.hour) do |request|
      request.ip if request.post? && request.path == '/proximity'
    end

    throttle('age_confirmation/create/ip', limit: 20, period: 1.hour) do |request|
      request.ip if request.post? && request.path == '/age_confirmation'
    end

    throttle('reports/create/ip', limit: 30, period: 1.hour) do |request|
      request.ip if request.post? && request.path.match?(%r{\A/posts/\d+/report\z})
    end

    self.throttled_responder = lambda do |request|
      retry_after = (request.env['rack.attack.match_data'] || {})[:period]
      [
        429,
        { 'Content-Type' => 'text/plain', 'Retry-After' => retry_after.to_s },
        ["Too many requests. Try again later.\n"]
      ]
    end
  end
end
