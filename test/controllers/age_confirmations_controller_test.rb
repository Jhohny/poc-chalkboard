# frozen_string_literal: true

require 'test_helper'

class AgeConfirmationsControllerTest < ActionDispatch::IntegrationTest
  test 'confirming age unlocks the location gate' do
    get root_url
    assert_includes @response.body, I18n.t('age_gate.heading')

    post age_confirmation_url
    assert_redirected_to root_path
    follow_redirect!

    assert_response :success
    assert_includes @response.body, I18n.t('gate.heading')
  end

  test 'revoking age confirmation restores the age gate' do
    confirm_age!

    delete age_confirmation_url
    assert_redirected_to root_path
    follow_redirect!

    assert_includes @response.body, I18n.t('age_gate.heading')
  end
end
