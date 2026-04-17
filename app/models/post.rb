# frozen_string_literal: true

# A single anonymous note pinned to a city wall.
class Post < ApplicationRecord
  MAX_BODY_LENGTH = 120
  POST_COOLDOWN = 1.minute
  LIFETIME = 48.hours
  COLOR_VARIANTS = %w[sky amber mint coral lilac cloud sun].freeze
  SIZE_VARIANTS = %w[small medium large].freeze

  validates :body, presence: true, length: { maximum: MAX_BODY_LENGTH }
  validates(
    :city_slug, :city_name, :pseudonym, :icon, :session_token_digest,
    :posted_at, :expires_at, :x_position, :y_position, :rotation,
    :color_variant, :size_variant,
    presence: true
  )
  validates :rotation, inclusion: { in: -6..6 }
  validates :color_variant, inclusion: { in: COLOR_VARIANTS }
  validates :size_variant, inclusion: { in: SIZE_VARIANTS }

  before_validation :normalize_body
  before_validation :apply_defaults

  validate :respect_rate_limit, on: :create
  validate :avoid_exact_repeat, on: :create

  scope :active, -> { where('expires_at > ?', Time.current) }
  scope :newest_first, -> { order(posted_at: :desc, id: :desc) }
  scope :visible_in_city, ->(city_slug) { active.where(city_slug: city_slug).newest_first }

  after_create_commit :broadcast_to_city

  def assign_wall_context(city:, identity:)
    self.city_slug = city.slug
    self.city_name = city.name
    self.pseudonym = identity.pseudonym
    self.icon = identity.icon
    self.session_token_digest = identity.digest
  end

  def note_opacity
    remaining = ((expires_at - Time.current) / LIFETIME).clamp(0.0, 1.0)
    (0.35 + (remaining * 0.65)).round(2)
  end

  def note_offset_x
    x_position || 0
  end

  def note_offset_y
    y_position || 0
  end

  def note_rotation
    rotation || 0
  end

  def city_stream_name
    "city_wall:#{city_slug}"
  end

  private

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
    self.x_position ||= rand(-22..22)
    self.y_position ||= rand(0..26)
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

    recent_posts = self.class.where(session_token_digest: session_token_digest)
    recent_post = recent_posts.where('posted_at >= ?', POST_COOLDOWN.ago).exists?

    errors.add(:body, 'can only be posted once per minute') if recent_post
  end

  def avoid_exact_repeat
    return if session_token_digest.blank? || body.blank?

    session_posts = self.class.active.where(session_token_digest: session_token_digest)
    repeated_post = session_posts.where('lower(body) = ?', body.downcase).exists?

    errors.add(:body, 'cannot repeat the exact same message') if repeated_post
  end

  def broadcast_to_city
    broadcast_prepend_later_to(
      city_stream_name,
      target: 'wall_posts',
      partial: 'posts/post',
      locals: { post: self }
    )
  end
end
