# frozen_string_literal: true

require 'test_helper'

class ReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    confirm_age!
    @post = posts(:one)
  end

  test 'increments the reports_count on a post' do
    assert_difference -> { @post.reload.reports_count }, 1 do
      post post_report_url(@post), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    end

    assert_response :success
  end

  test 'is idempotent per session' do
    post post_report_url(@post), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

    assert_no_difference -> { @post.reload.reports_count } do
      post post_report_url(@post), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    end
  end

  test 'auto-hides a post once reports reach the threshold' do
    @post.update!(reports_count: Post::AUTO_HIDE_THRESHOLD - 1)

    reset!
    confirm_age!
    post post_report_url(@post), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

    assert @post.reload.reports_count >= Post::AUTO_HIDE_THRESHOLD
    assert_not Post.active.exists?(@post.id), 'reported post should leave the active scope'
  end

  test 'rejects reports without age confirmation' do
    reset!

    post post_report_url(@post), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

    assert_response :unprocessable_entity
  end
end
