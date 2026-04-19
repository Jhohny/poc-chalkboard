# frozen_string_literal: true

# Shared controller behavior for the anonymous wall.
class ApplicationController < ActionController::Base
  include CurrentLocation

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :session_identity

  private

  def session_identity
    @session_identity ||= SessionIdentity.fetch(session)
  end
end
