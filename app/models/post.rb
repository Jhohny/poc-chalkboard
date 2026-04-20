# frozen_string_literal: true

# A single anonymous note pinned to a set of (fuzzed) coordinates.
class Post < ApplicationRecord
  include Proximity
  include BodyPolicy

  MAX_BODY_LENGTH = 120
  POST_COOLDOWN = 1.minute
  LIFETIME = 48.hours
  AUTO_HIDE_THRESHOLD = 5
  COLOR_VARIANTS = %w[sky amber mint coral lilac cloud sun].freeze
  SIZE_VARIANTS = %w[small medium large].freeze

  validates :body, presence: true, length: { maximum: MAX_BODY_LENGTH }
  validates(
    :pseudonym, :icon, :session_token_digest,
    :posted_at, :expires_at, :rotation,
    :color_variant, :size_variant,
    :latitude, :longitude,
    presence: true
  )
  validates :latitude,  numericality: { greater_than_or_equal_to: -90,  less_than_or_equal_to: 90 }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
  validates :rotation, inclusion: { in: -6..6 }
  validates :color_variant, inclusion: { in: COLOR_VARIANTS }
  validates :size_variant, inclusion: { in: SIZE_VARIANTS }

  before_validation :normalize_body
  before_validation :apply_defaults

  validate :respect_rate_limit, on: :create
  validate :avoid_exact_repeat, on: :create

  scope :active, lambda {
    where(hidden_at: nil)
      .where('reports_count < ?', AUTO_HIDE_THRESHOLD)
      .where('expires_at > ?', Time.current)
  }
  scope :newest_first, -> { order(posted_at: :desc, id: :desc) }

  def assign_proximity_context(location:, identity:)
    self.pseudonym = identity.pseudonym
    self.icon = identity.icon
    self.session_token_digest = identity.digest
    apply_proximity_fuzz(location.latitude, location.longitude, identity.token)
  end

  def note_opacity
    remaining = ((expires_at - Time.current) / LIFETIME).clamp(0.0, 1.0)
    (0.35 + (remaining * 0.65)).round(2)
  end

  def note_rotation
    rotation || 0
  end

  def ranked_score
    decay = 1.0 / (1 + distance_to_reference)
    (decay * freshness_factor) + (rand * 0.1)
  end

  private

  def distance_to_reference
    return read_attribute(:distance_km).to_f if has_attribute?(:distance_km)

    0.0
  end

  def freshness_factor
    age_hours = (Time.current - posted_at) / 3600.0
    return 1.0 if age_hours <= 2

    [0.0, 1 - ((age_hours - 2) / 46.0)].max
  end

  def normalize_body
    self.body = body.to_s.squish
  end

  def apply_defaults
    return if body.blank?

    apply_timing_defaults
    apply_visual_defaults
  end

  def apply_timing_defaults
    self.posted_at ||= Time.current
    self.expires_at ||= posted_at + LIFETIME if posted_at
  end

  def apply_visual_defaults
    self.rotation ||= rand(-4..4)
    self.color_variant ||= COLOR_VARIANTS.sample
    self.size_variant ||= infer_size_variant
  end

  def infer_size_variant
    return 'small' if body.length <= 32
    return 'medium' if body.length <= 80

    'large'
  end

  def respect_rate_limit
    return if session_token_digest.blank?

    recent_post = self.class
                      .where(session_token_digest: session_token_digest)
                      .where('posted_at >= ?', POST_COOLDOWN.ago)
                      .exists?

    errors.add(:body, 'can only be posted once per minute') if recent_post
  end

  def avoid_exact_repeat
    return if session_token_digest.blank? || body.blank?

    repeated = self.class.active
                   .where(session_token_digest: session_token_digest)
                   .where('lower(body) = ?', body.downcase)
                   .exists?

    errors.add(:body, 'cannot repeat the exact same message') if repeated
  end
end
