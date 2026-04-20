# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_20_053933) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "posts", force: :cascade do |t|
    t.string "body", null: false
    t.string "color_variant", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.datetime "hidden_at"
    t.string "icon", null: false
    t.decimal "latitude", precision: 9, scale: 6, null: false
    t.decimal "longitude", precision: 9, scale: 6, null: false
    t.datetime "posted_at", null: false
    t.string "pseudonym", null: false
    t.integer "reports_count", default: 0, null: false
    t.integer "rotation", null: false
    t.string "session_token_digest", null: false
    t.string "size_variant", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_posts_on_expires_at"
    t.index ["hidden_at"], name: "index_posts_on_hidden_at"
    t.index ["latitude", "longitude"], name: "index_posts_on_latitude_and_longitude"
    t.index ["posted_at", "id"], name: "index_posts_on_posted_at_and_id"
    t.index ["session_token_digest", "posted_at"], name: "index_posts_on_session_token_digest_and_posted_at"
  end
end
