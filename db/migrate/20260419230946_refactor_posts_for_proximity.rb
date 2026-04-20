# frozen_string_literal: true

class RefactorPostsForProximity < ActiveRecord::Migration[8.1]
  def up
    execute 'DELETE FROM posts'

    change_table :posts do |t|
      t.decimal :latitude,  precision: 9, scale: 6, null: false
      t.decimal :longitude, precision: 9, scale: 6, null: false
      t.remove :city_slug, :city_name, :x_position, :y_position
    end

    add_index :posts, %i[latitude longitude]
    add_index :posts, %i[posted_at id]
  end

  def down
    change_table :posts do |t|
      t.string :city_slug
      t.string :city_name
      t.integer :x_position
      t.integer :y_position
      t.remove :latitude, :longitude
    end

    add_index :posts, %i[city_slug posted_at id]
    remove_index :posts, %i[posted_at id]
  end
end
