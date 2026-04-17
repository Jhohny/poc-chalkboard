# frozen_string_literal: true

# Handles wall note pagination and submission.
class PostsController < ApplicationController
  PER_PAGE = WallsController::PER_PAGE

  before_action :require_city!

  def index
    @posts = posts_scope
    @next_cursor = @posts.last&.posted_at&.to_i

    render turbo_stream: [
      turbo_stream.append('wall_posts', partial: 'posts/post', collection: @posts, as: :post),
      turbo_stream.replace('wall_pagination', partial: 'posts/pagination', locals: { next_cursor: @next_cursor })
    ]
  end

  def create
    @post = Post.new(post_params)
    @post.assign_wall_context(city: current_city, identity: session_identity)

    if @post.save
      render_composer(post: Post.new, status_message: "Pinned to #{current_city.name}.")
    else
      render_composer(post: @post, status_message: nil, status: :unprocessable_entity)
    end
  end

  private

  def post_params
    params.expect(post: [:body])
  end

  def posts_scope
    scope = Post.visible_in_city(current_city.slug)
    scope = scope.where('posted_at < ?', Time.at(params[:before].to_i)) if params[:before].present?
    scope.limit(PER_PAGE)
  end

  def require_city!
    head :unprocessable_entity unless current_city
  end

  def composer_locals(post, status_message)
    {
      post: post,
      city: current_city,
      identity: session_identity,
      status_message: status_message
    }
  end

  def render_composer(post:, status_message:, status: :ok)
    render turbo_stream: turbo_stream.replace(
      'composer',
      partial: 'posts/composer',
      locals: composer_locals(post, status_message)
    ), status: status
  end
end
