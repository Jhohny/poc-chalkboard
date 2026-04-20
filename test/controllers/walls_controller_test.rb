# frozen_string_literal: true

require 'test_helper'

class WallsControllerTest < ActionDispatch::IntegrationTest
  test 'renders the location gate when the visitor has no stored location' do
    get root_url

    assert_response :success
    assert_includes @response.body, I18n.t('gate.heading')
    assert_not_includes @response.body, posts(:one).body
  end

  test 'renders nearby cards once the location is known' do
    post proximity_url, params: { latitude: 37.7749, longitude: -122.4194 }, as: :json
    assert_response :created

    get root_url

    assert_response :success
    assert_includes @response.body, posts(:one).body
  end

  test 'Spanish locale renders translated copy' do
    get root_url, headers: { 'Accept-Language' => 'es' }

    assert_response :success
    assert_includes @response.body, I18n.t('gate.heading', locale: :es)
  end
end
