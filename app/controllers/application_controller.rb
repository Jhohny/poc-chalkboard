# frozen_string_literal: true

# Shared controller behavior for the anonymous wall.
class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_city, :session_identity

  private

  def current_city
    @current_city ||= CityLocator.call(request)
  end

  def session_identity
    @session_identity ||= SessionIdentity.fetch(session)
  end
end
