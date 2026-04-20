# frozen_string_literal: true

# Shared controller behavior for the anonymous wall.
class ApplicationController < ActionController::Base
  include AgeVerified
  include CurrentProximity

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_locale

  helper_method :session_identity

  private

  def session_identity
    @session_identity ||= SessionIdentity.fetch(session)
  end

  def set_locale
    I18n.locale = extract_locale || I18n.default_locale
  end

  def extract_locale
    accept = request.env['HTTP_ACCEPT_LANGUAGE'].to_s
    accept.scan(/[a-z]{2}/).find { |code| I18n.available_locales.map(&:to_s).include?(code) }&.to_sym
  end
end
