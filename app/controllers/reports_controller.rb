# frozen_string_literal: true

# Accepts a report on a single post. One report per session per post — the
# session carries the list of already-reported IDs, so a double-tap doesn't
# double-count. Once a post crosses AUTO_HIDE_THRESHOLD, the `active` scope
# drops it from the public feed; an admin can still see it under /admin/posts.
class ReportsController < ApplicationController
  before_action :require_age_confirmation!

  def create
    increment_reports_count unless reported_post_ids.include?(post_id)
    remember_report(post_id)
    respond_with_removal
  end

  private

  def post_id
    @post_id ||= params[:post_id].to_i
  end

  def increment_reports_count
    Post.where(id: post_id).update_all('reports_count = reports_count + 1')
  end

  def respond_with_removal
    respond_to do |format|
      format.turbo_stream do
        dom_id = ActionView::RecordIdentifier.dom_id(Post.new(id: post_id))
        render turbo_stream: turbo_stream.remove(dom_id)
      end
      format.any { head :no_content }
    end
  end

  def reported_post_ids
    Array(session[:reported_post_ids])
  end

  def remember_report(id)
    session[:reported_post_ids] = (reported_post_ids + [ id ]).uniq.last(200)
  end
end
