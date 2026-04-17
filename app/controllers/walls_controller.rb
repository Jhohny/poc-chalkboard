# frozen_string_literal: true

# Renders the city wall homepage.
class WallsController < ApplicationController
  PER_PAGE = 18

  def show
    return unless current_city

    @post = Post.new
    @posts = Post.visible_in_city(current_city.slug).limit(PER_PAGE)
    @next_cursor = @posts.last&.posted_at&.to_i
  end
end
