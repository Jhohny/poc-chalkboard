# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'digest'

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

module ActionDispatch
  class IntegrationTest
    include ActiveSupport::Testing::TimeHelpers

    # Simulates the visitor tapping "I'm 18 or older" on the age gate.
    # Most integration tests exercise the feed, which is gated behind
    # age confirmation — call this in `setup` to get past it.
    def confirm_age!
      post age_confirmation_url
      follow_redirect!
    end
  end
end
