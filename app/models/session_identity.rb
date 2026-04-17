# frozen_string_literal: true

require 'digest'

# Session-backed anonymous identity for a browser session.
class SessionIdentity
  ICONS = %w[✦ ★ ☺ ☼ ✎ ♣ ♠ ♥ ♦ ☁ ☕ ☘ ☾ ♪].freeze
  ADJECTIVES = %w[Quiet Local Neon Wandering Tin Soft Hidden Electric Paper Sidewalk North South].freeze
  NOUNS = %w[Sparrow Lantern Window Echo Marker Comet Kite River Brick Moth Signal Marble Haze].freeze

  attr_reader :token, :pseudonym, :icon

  def self.fetch(session)
    new(session)
  end

  def initialize(session)
    @session = session
    @token = session[:wall_session_token].presence || SecureRandom.hex(16)
    @pseudonym = session[:wall_pseudonym].presence || generate_pseudonym
    @icon = session[:wall_icon].presence || ICONS.sample

    persist!
  end

  def digest
    @digest ||= Digest::SHA256.hexdigest(token)
  end

  private

  attr_reader :session

  def persist!
    session[:wall_session_token] = token
    session[:wall_pseudonym] = pseudonym
    session[:wall_icon] = icon
  end

  def generate_pseudonym
    "#{ADJECTIVES.sample} #{NOUNS.sample}"
  end
end
