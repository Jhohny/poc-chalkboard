# frozen_string_literal: true

# Adds hidden_at (admin soft-delete timestamp) and reports_count
# (increments via ReportsController; auto-hide threshold lives in Post).
class AddModerationFieldsToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :hidden_at,     :datetime
    add_column :posts, :reports_count, :integer, null: false, default: 0
    add_index  :posts, :hidden_at
  end
end
