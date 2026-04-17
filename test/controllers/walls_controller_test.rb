# frozen_string_literal: true

require 'test_helper'

class WallsControllerTest < ActionDispatch::IntegrationTest
  test 'shows the detected city wall' do
    get root_url, headers: { 'X-App-City' => 'San Francisco' }

    assert_response :success
    assert_includes @response.body, 'San Francisco is writing.'
    assert_includes @response.body, 'First pinned thought'
  end

  test 'shows unavailable state when city detection fails' do
    get root_url

    assert_response :success
    assert_includes @response.body, 'Service unavailable for your area'
  end
end
