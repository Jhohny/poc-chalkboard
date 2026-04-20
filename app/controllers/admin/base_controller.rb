# frozen_string_literal: true

module Admin
  # Shared base for /admin — HTTP basic auth plus a bypass of the age +
  # proximity gates that the public app uses.
  #
  # Credentials are read at request time (via the block below) rather than
  # captured at class-load time, so tests can set ENV vars in `setup`. In
  # production, missing ADMIN_PASSWORD falls back to a random value so the
  # admin is locked out by default rather than exposed with a weak default.
  class BaseController < ApplicationController
    DEV_FALLBACK_PASSWORD = 'admin'

    skip_before_action :require_age_confirmation!, raise: false

    before_action :authenticate_admin!

    private

    def authenticate_admin!
      authenticate_or_request_with_http_basic('Admin') do |username, password|
        ActiveSupport::SecurityUtils.secure_compare(username, admin_username) &
          ActiveSupport::SecurityUtils.secure_compare(password, admin_password)
      end
    end

    def admin_username
      ENV.fetch('ADMIN_USERNAME', 'admin')
    end

    def admin_password
      ENV.fetch('ADMIN_PASSWORD') do
        Rails.env.development? ? DEV_FALLBACK_PASSWORD : SecureRandom.hex(32)
      end
    end
  end
end
