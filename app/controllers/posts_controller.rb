# frozen_string_literal: true

# Handles note submission and polling for new nearby notes.
class PostsController < ApplicationController
  MAX_CANDIDATES = WallsController::MAX_CANDIDATES

  before_action :require_location!

  def index
    @cards = new_cards_since(params[:since])

    render turbo_stream: turbo_stream.prepend(
      'card_stack',
      partial: 'posts/card',
      collection: @cards,
      as: :post
    )
  end

  def create
    @post = Post.new(post_params)
    @post.assign_proximity_context(location: current_proximity, identity: session_identity)

    if @post.save
      render_composer(post: Post.new, status_message: t('composer.pinned'),
                      prepend_card: @post)
    else
      render_composer(post: @post, status_message: nil, status: :unprocessable_entity)
    end
  end

  private

  def post_params
    params.expect(post: [:body])
  end

  def new_cards_since(timestamp_iso)
    scope = Post.active
                .within_km(current_proximity.latitude, current_proximity.longitude, current_radius_or_default)
                .limit(MAX_CANDIDATES)
    scope = scope.where('posted_at > ?', Time.zone.parse(timestamp_iso)) if timestamp_iso.present?
    scope.sort_by { |p| -p.ranked_score }
  end

  def current_radius_or_default
    current_radius_km || Proximity::MAX_RADIUS_KM
  end

  def require_location!
    return if location_known?

    respond_to do |format|
      format.turbo_stream { head :unprocessable_entity }
      format.html         { head :unprocessable_entity }
      format.any          { head :unprocessable_entity }
    end
  end

  def render_composer(post:, status_message:, status: :ok, prepend_card: nil)
    streams = [
      turbo_stream.replace(
        'composer',
        partial: 'posts/composer_sheet',
        locals: { post: post, identity: session_identity, status_message: status_message }
      )
    ]
    streams << turbo_stream.prepend('card_stack', partial: 'posts/card', locals: { post: prepend_card }) if prepend_card

    render turbo_stream: streams, status: status
  end
end
