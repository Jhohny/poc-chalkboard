# frozen_string_literal: true

require 'test_helper'

class PostTest < ActiveSupport::TestCase
  setup do
    @city = CityLocator::City.new(name: 'San Francisco', slug: 'san-francisco')
  end

  test 'assigns defaults and validates a valid post' do
    identity = SessionIdentity.new({})
    post = Post.new(body: 'Small local note')

    post.assign_wall_context(city: @city, identity: identity)

    assert post.valid?
    assert_equal 'San Francisco', post.city_name
    assert_equal identity.pseudonym, post.pseudonym
    assert_equal identity.icon, post.icon
    assert post.expires_at > post.posted_at
  end

  test 'blocks repeat submissions from the same session' do
    identity = Struct.new(:pseudonym, :icon, :digest).new('Quiet Echo', '✦', posts(:one).session_token_digest)
    post = Post.new(body: posts(:one).body)

    post.assign_wall_context(city: @city, identity: identity)

    assert_not post.valid?
    assert_includes post.errors[:body], 'cannot repeat the exact same message'
  end

  test 'enforces a one minute cooldown' do
    digest = Digest::SHA256.hexdigest('fresh-session')
    Post.create!(
      city_slug: 'san-francisco',
      city_name: 'San Francisco',
      pseudonym: 'Quiet Echo',
      icon: '✦',
      body: 'Just posted this one',
      x_position: 0,
      y_position: 0,
      rotation: 0,
      color_variant: 'sky',
      size_variant: 'small',
      posted_at: 30.seconds.ago,
      expires_at: 2.days.from_now,
      session_token_digest: digest
    )
    identity = Struct.new(:pseudonym, :icon, :digest).new('Quiet Echo', '✦', digest)
    post = Post.new(body: 'Trying again too fast')

    post.assign_wall_context(city: @city, identity: identity)

    assert_not post.valid?
    assert_includes post.errors[:body], 'can only be posted once per minute'
  end
end
