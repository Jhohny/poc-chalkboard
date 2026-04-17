class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.string :city_slug, null: false
      t.string :city_name, null: false
      t.string :pseudonym, null: false
      t.string :icon, null: false
      t.string :body, null: false
      t.integer :x_position, null: false
      t.integer :y_position, null: false
      t.integer :rotation, null: false
      t.string :color_variant, null: false
      t.string :size_variant, null: false
      t.datetime :posted_at, null: false
      t.datetime :expires_at, null: false
      t.string :session_token_digest, null: false

      t.timestamps
    end

    add_index :posts, [ :city_slug, :posted_at, :id ]
    add_index :posts, :expires_at
    add_index :posts, [ :session_token_digest, :posted_at ]
  end
end
