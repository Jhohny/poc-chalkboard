# frozen_string_literal: true

require 'test_helper'

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    confirm_age!
    post proximity_url, params: { latitude: 37.7749, longitude: -122.4194 }, as: :json
    assert_response :created
  end

  test 'creates a post with fuzzed coordinates close to the stored location' do
    assert_difference('Post.count', 1) do
      post posts_url,
           params: { post: { body: 'Fresh note for the wall' } },
           headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    end

    assert_response :success
    created = Post.order(:created_at).last
    bound = Proximity::FUZZ_DEGREES + Proximity::JITTER_DEGREES
    assert_in_delta 37.7749, created.latitude.to_f, bound
    assert_in_delta(-122.4194, created.longitude.to_f, bound)
  end

  test 'rejects exact repeats from the same session' do
    post posts_url,
         params: { post: { body: 'Repeat me once' } },
         headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    assert_response :success

    assert_no_difference('Post.count') do
      travel 61.seconds do
        post posts_url,
             params: { post: { body: 'Repeat me once' } },
             headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      end
    end

    assert_response :unprocessable_entity
    assert_includes @response.body, 'cannot repeat the exact same message'
  end

  test 'index returns prepended cards for notes newer than :since' do
    post posts_url,
         params: { post: { body: 'Very new note' } },
         headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    assert_response :success

    get posts_url(since: 5.minutes.ago.iso8601, format: :turbo_stream)
    assert_response :success
    assert_includes @response.body, 'Very new note'
  end

  test 'rejects post creation when no location is stored' do
    delete proximity_url
    assert_response :no_content

    post posts_url,
         params: { post: { body: 'Should not save' } },
         headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

    assert_response :unprocessable_entity
  end
end
