# frozen_string_literal: true

module Admin
  # Minimal moderation dashboard: list posts (reported first) and soft-delete.
  class PostsController < BaseController
    def index
      @posts = Post
               .order(Arel.sql('reports_count DESC NULLS LAST'), posted_at: :desc)
               .limit(200)
    end

    def destroy
      post = Post.find(params[:id])
      post.update!(hidden_at: Time.current)
      redirect_to admin_posts_path, notice: 'Hidden.'
    end
  end
end
