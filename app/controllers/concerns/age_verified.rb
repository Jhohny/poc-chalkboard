# frozen_string_literal: true

# Tracks the visitor's 18+ self-confirmation in session.
#
# Writing age confirmation to the session (rather than a cookie or the
# database) keeps the POC zero-PII: the confirmation evaporates when the
# session does. `AgeConfirmationsController` stamps the timestamp; the
# controllers that expose the feed call `require_age_confirmation!`.
module AgeVerified
  extend ActiveSupport::Concern

  AGE_CONFIRMATION_TTL = 365.days

  included do
    helper_method :age_confirmed?
  end

  def age_confirmed?
    confirmed_at = session[:age_confirmed_at]
    return false if confirmed_at.blank?

    Time.zone.parse(confirmed_at.to_s) > AGE_CONFIRMATION_TTL.ago
  rescue ArgumentError, TypeError
    false
  end

  def confirm_age!
    session[:age_confirmed_at] = Time.current.iso8601
  end

  def revoke_age_confirmation!
    session.delete(:age_confirmed_at)
  end

  def require_age_confirmation!
    return if age_confirmed?

    respond_to do |format|
      format.html         { redirect_to root_path }
      format.turbo_stream { head :unprocessable_entity }
      format.any          { head :unprocessable_entity }
    end
  end
end
