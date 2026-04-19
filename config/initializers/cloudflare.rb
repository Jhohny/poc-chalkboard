# frozen_string_literal: true

# cloudflare-rails automatically fetches Cloudflare's published IP ranges on boot
# and registers them with ActionDispatch::RemoteIp as trusted proxies.
#
# This ensures request.remote_ip reflects the real visitor IP rather than a
# Cloudflare edge node IP, which matters for geocoder fallback and rate limiting.
#
# No manual configuration is required — the gem handles range updates via a
# Railtie. See: https://github.com/modosc/cloudflare-rails
