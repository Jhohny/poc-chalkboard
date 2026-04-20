# frozen_string_literal: true

require 'test_helper'

class BodyPolicyTest < ActiveSupport::TestCase
  DEFAULTS = {
    pseudonym: 'Quiet Echo', icon: '✦',
    latitude: 37.7749, longitude: -122.4194,
    rotation: 0, color_variant: 'sky', size_variant: 'small',
    posted_at: -> { Time.current }, expires_at: -> { 48.hours.from_now }
  }.freeze

  def build_post(body)
    attrs = DEFAULTS.transform_values { |value| value.respond_to?(:call) ? value.call : value }
    Post.new(attrs.merge(body: body, session_token_digest: Digest::SHA256.hexdigest(SecureRandom.hex(8))))
  end

  test 'rejects https links' do
    post = build_post('check this out https://spam.example.com')
    assert_not post.valid?
    assert_includes post.errors[:body], 'cannot contain links or URLs'
  end

  test 'rejects http links' do
    post = build_post('http://bad.tld is a problem')
    assert_not post.valid?
  end

  test 'rejects www. prefixes' do
    post = build_post('just hit up www.somewhere.tld')
    assert_not post.valid?
  end

  test 'rejects bare hosts' do
    post = build_post('ping foo.com later')
    assert_not post.valid?
  end

  test 'allows plain human sentences' do
    post = build_post('the fog rolled in early today')
    assert post.valid?, post.errors.full_messages.inspect
  end

  test 'allows numbers and punctuation' do
    post = build_post("third coffee, still can't focus — worth it?")
    assert post.valid?, post.errors.full_messages.inspect
  end
end
