# frozen_string_literal: true

# Rejects note bodies that contain anything URL-shaped.
#
# The wall is intentionally plain text — links invite spam, drive-by
# phishing, and referral scams, and there's nothing valuable a 120-char
# note can express with a link that can't be said without one.
module BodyPolicy
  extend ActiveSupport::Concern

  URL_PATTERN = %r{
    (?:https?://)          |  # explicit scheme
    (?:www\.[^\s]+)        |  # www. prefix
    (?:\b[a-z0-9][a-z0-9-]{1,}\.[a-z]{2,}\b)  # bare host like "foo.com"
  }ix

  included do
    validate :reject_urls_in_body, on: :create
  end

  private

  def reject_urls_in_body
    return if body.blank?
    return unless body.match?(URL_PATTERN)

    errors.add(:body, 'cannot contain links or URLs')
  end
end
