# frozen_string_literal: true

require 'test_helper'

module Admin
  class PostsControllerTest < ActionDispatch::IntegrationTest
    ADMIN_USERNAME = 'admin-test'
    ADMIN_PASSWORD = 'p4ssw0rd'

    setup do
      ENV['ADMIN_USERNAME'] = ADMIN_USERNAME
      ENV['ADMIN_PASSWORD'] = ADMIN_PASSWORD
    end

    teardown do
      ENV.delete('ADMIN_USERNAME')
      ENV.delete('ADMIN_PASSWORD')
    end

    test 'rejects unauthenticated access' do
      get admin_posts_url

      assert_response :unauthorized
    end

    test 'renders the post list for an authenticated admin' do
      get admin_posts_url, headers: auth_headers

      assert_response :success
      assert_includes @response.body, posts(:one).body
    end

    test 'destroy soft-hides the post' do
      target = posts(:one)

      delete admin_post_url(target), headers: auth_headers

      assert_redirected_to admin_posts_path
      assert_not_nil target.reload.hidden_at
    end

    private

    def auth_headers
      credentials = ActionController::HttpAuthentication::Basic.encode_credentials(ADMIN_USERNAME, ADMIN_PASSWORD)
      { 'Authorization' => credentials }
    end
  end
end
