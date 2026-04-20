# frozen_string_literal: true

require 'test_helper'

class ProximityControllerTest < ActionDispatch::IntegrationTest
  test 'stores valid coordinates in session' do
    post proximity_url, params: { latitude: 37.7749, longitude: -122.4194 }, as: :json

    assert_response :created
    body = JSON.parse(@response.body)
    assert body['ok']

    # Subsequent requests now see the location.
    get root_url
    assert_response :success
    assert_includes @response.body, posts(:one).body
  end

  test 'rejects out-of-range coordinates' do
    post proximity_url, params: { latitude: 120, longitude: 999 }, as: :json

    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_not body['ok']
  end

  test 'rejects non-numeric coordinates' do
    post proximity_url, params: { latitude: 'hello', longitude: 'there' }, as: :json

    assert_response :unprocessable_entity
  end

  test 'destroy clears the stored coordinates' do
    post proximity_url, params: { latitude: 37.7749, longitude: -122.4194 }, as: :json
    delete proximity_url

    assert_response :no_content

    get root_url
    assert_includes @response.body, I18n.t('gate.heading')
  end
end
