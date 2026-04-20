# frozen_string_literal: true

# Renders the proximity feed homepage.
class WallsController < ApplicationController
  MAX_CANDIDATES = 200

  def show
    return unless location_known?

    candidates = nearby_candidates
    @radius_km = select_radius(candidates)
    @cards = rank_within_radius(candidates, @radius_km)
  end

  private

  def nearby_candidates
    Post.active
        .within_km(current_proximity.latitude, current_proximity.longitude, Proximity::MAX_RADIUS_KM)
        .limit(MAX_CANDIDATES)
        .to_a
  end

  def select_radius(candidates)
    radius = current_radius_km || Post.choose_radius(candidates.map { |p| p.read_attribute(:distance_km).to_f })
    cache_radius_km(radius)
    radius
  end

  def rank_within_radius(candidates, radius_km)
    candidates
      .select { |post| post.read_attribute(:distance_km).to_f <= radius_km }
      .sort_by { |post| -post.ranked_score }
  end
end
