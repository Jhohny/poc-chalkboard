# frozen_string_literal: true

require 'test_helper'

class PostsControllerTest < ActionDispatch::IntegrationTest
  test 'creates a post for the current city' do
    get root_url, headers: { 'X-App-City' => 'San Francisco' }

    assert_difference('Post.count', 1) do
      post posts_url,
           params: { post: { body: 'Fresh note for the wall' } },
           headers: {
             'X-App-City' => 'San Francisco',
             'Accept' => 'text/vnd.turbo-stream.html'
           }
    end

    assert_response :success
    assert_equal 'San Francisco', Post.order(:created_at).last.city_name
  end

  test 'rejects exact repeats from the same session' do
    get root_url, headers: { 'X-App-City' => 'San Francisco' }

    post posts_url,
         params: { post: { body: 'Repeat me once' } },
         headers: {
           'X-App-City' => 'San Francisco',
           'Accept' => 'text/vnd.turbo-stream.html'
         }

    assert_no_difference('Post.count') do
      travel 61.seconds do
        post posts_url,
             params: { post: { body: 'Repeat me once' } },
             headers: {
               'X-App-City' => 'San Francisco',
               'Accept' => 'text/vnd.turbo-stream.html'
             }
      end
    end

    assert_response :unprocessable_entity
    assert_includes @response.body, 'cannot repeat the exact same message'
  end
end
