# frozen_string_literal: true

require 'test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
  test 'terms renders in English by default' do
    get terms_url

    assert_response :success
    assert_includes @response.body, I18n.t('legal.terms.title')
    assert_includes @response.body, 'You must be 18 or older'
  end

  test 'privacy renders in English by default' do
    get privacy_url

    assert_response :success
    assert_includes @response.body, I18n.t('legal.privacy.title')
    assert_includes @response.body, 'fuzzed'
  end

  test 'privacy renders in Spanish when requested' do
    get privacy_url, headers: { 'Accept-Language' => 'es' }

    assert_response :success
    assert_includes @response.body, I18n.t('legal.privacy.title', locale: :es)
    assert_includes @response.body, 'difuminan'
  end

  test 'terms and privacy are accessible without age confirmation' do
    get terms_url
    assert_response :success

    get privacy_url
    assert_response :success
  end
end
