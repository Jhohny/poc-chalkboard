# frozen_string_literal: true

require 'test_helper'

class RackAttackTest < ActionDispatch::IntegrationTest
  # Test env's Rails.cache is a :null_store, so Rack::Attack's counters never
  # increment. Swap in a real in-memory store just for this test case.
  setup do
    @original_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    confirm_age!
    post proximity_url, params: { latitude: 37.7749, longitude: -122.4194 }, as: :json
    assert_response :created
  end

  teardown do
    Rack::Attack.cache.store = @original_store
  end

  test 'throttles POST /posts past the per-IP limit' do
    limit = 10

    limit.times do |index|
      post posts_url,
           params: { post: { body: "burst note #{index}" } },
           headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    end

    travel 61.seconds do
      post posts_url,
           params: { post: { body: 'this should get throttled' } },
           headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    end

    post posts_url,
         params: { post: { body: 'this one is over the limit' } },
         headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

    assert_response :too_many_requests
    assert_includes @response.body, 'Too many requests'
  end
end
