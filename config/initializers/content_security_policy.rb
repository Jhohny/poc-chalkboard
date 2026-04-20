# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.script_src  :self
    # Google Fonts is pulled in from the application layout; allow it
    # explicitly instead of blanket :https.
    policy.style_src   :self, 'https://fonts.googleapis.com'
    policy.font_src    :self, 'https://fonts.gstatic.com'
    policy.connect_src :self
    policy.img_src     :self, :data
    policy.object_src  :none
    policy.frame_ancestors :none
    policy.base_uri    :self
    policy.form_action :self
  end

  # Use CSP nonces for inline <style> blocks so we can drop 'unsafe-inline'.
  # Stimulus-managed styles on cards apply CSS variables via JS; the only
  # inline styles we generate come from the per-card rotation/opacity nonce
  # block, which uses `content_security_policy_nonce` in the view.
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[style-src script-src]
end
