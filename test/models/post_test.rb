# frozen_string_literal: true

require 'test_helper'

class PostTest < ActiveSupport::TestCase
  Location = Struct.new(:latitude, :longitude)

  setup do
    @location = Location.new(37.7749, -122.4194)
  end

  test 'assigns defaults and validates a valid post' do
    identity = SessionIdentity.new({})
    post = Post.new(body: 'Small local note')

    post.assign_proximity_context(location: @location, identity: identity)

    assert post.valid?, post.errors.full_messages.inspect
    assert_equal identity.pseudonym, post.pseudonym
    assert_equal identity.icon, post.icon
    assert post.expires_at > post.posted_at
  end

  test 'applies session-stable fuzz within FUZZ_DEGREES plus jitter' do
    identity = SessionIdentity.new({})
    post = Post.new(body: 'Small local note')

    post.assign_proximity_context(location: @location, identity: identity)

    bound = Proximity::FUZZ_DEGREES + Proximity::JITTER_DEGREES
    assert_in_delta @location.latitude,  post.latitude.to_f,  bound
    assert_in_delta @location.longitude, post.longitude.to_f, bound
  end

  test 'same session produces the same stable offset across posts' do
    identity = SessionIdentity.new({})
    offsets = 5.times.map do
      post = Post.new(body: SecureRandom.hex(4))
      post.assign_proximity_context(location: @location, identity: identity)
      [ post.latitude.to_f - @location.latitude, post.longitude.to_f - @location.longitude ]
    end

    # After subtracting the ±JITTER_DEGREES per-post noise, all offsets collapse
    # to the same session-stable ± FUZZ_DEGREES value (within jitter tolerance).
    lat_spread = offsets.map(&:first).max - offsets.map(&:first).min
    lng_spread = offsets.map(&:last).max  - offsets.map(&:last).min
    assert_operator lat_spread, :<=, (2 * Proximity::JITTER_DEGREES) + 0.00001
    assert_operator lng_spread, :<=, (2 * Proximity::JITTER_DEGREES) + 0.00001
  end

  test 'blocks repeat submissions from the same session' do
    existing = posts(:one)
    identity = Struct.new(:token, :pseudonym, :icon, :digest).new(
      'whatever', 'Quiet Echo', '✦', existing.session_token_digest
    )
    post = Post.new(body: existing.body)

    post.assign_proximity_context(location: @location, identity: identity)

    assert_not post.valid?
    assert_includes post.errors[:body], 'cannot repeat the exact same message'
  end

  test 'enforces a one minute cooldown' do
    digest = Digest::SHA256.hexdigest('fresh-session')
    Post.create!(
      pseudonym: 'Quiet Echo',
      icon: '✦',
      body: 'Just posted this one',
      latitude: 37.7749,
      longitude: -122.4194,
      rotation: 0,
      color_variant: 'sky',
      size_variant: 'small',
      posted_at: 30.seconds.ago,
      expires_at: 2.days.from_now,
      session_token_digest: digest
    )
    identity = Struct.new(:token, :pseudonym, :icon, :digest).new(
      'fresh-session', 'Quiet Echo', '✦', digest
    )
    post = Post.new(body: 'Trying again too fast')

    post.assign_proximity_context(location: @location, identity: identity)

    assert_not post.valid?
    assert_includes post.errors[:body], 'can only be posted once per minute'
  end

  test 'within_km returns posts within the radius and annotates distance_km' do
    sf_lat = 37.7749
    sf_lng = -122.4194

    nearby = Post.active.within_km(sf_lat, sf_lng, 5).to_a
    wider  = Post.active.within_km(sf_lat, sf_lng, 25).to_a

    assert_includes nearby.map(&:id), posts(:one).id
    assert_not_includes nearby.map(&:id), posts(:two).id
    assert_includes wider.map(&:id), posts(:two).id

    reloaded = Post.active.within_km(sf_lat, sf_lng, 25).find(posts(:one).id)
    assert_operator reloaded.distance_to(sf_lat, sf_lng), :<, 1.0
  end

  test 'choose_radius picks smallest tier meeting MIN_BATCH' do
    distances = [ 1, 2, 2.5, 2.9, 3, 4, 7 ]
    assert_equal 3, Post.choose_radius(distances)

    sparse = [ 1, 4, 9, 10, 24 ]
    assert_equal 25, Post.choose_radius(sparse)
  end
end
