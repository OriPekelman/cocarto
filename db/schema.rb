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

ActiveRecord::Schema[7.0].define(version: 2022_07_20_143402) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_enum :field_type, [
    "text",
    "float",
    "integer",
    "territory",
    "date",
    "boolean",
  ], force: :cascade

  create_enum :layer_geometry_type, [
    "point",
    "line_string",
    "polygon",
    "territory",
  ], force: :cascade

  create_enum :role_type, [
    "owner",
    "editor",
    "contributor",
    "viewer",
  ], force: :cascade

  create_table "fields", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "label"
    t.uuid "layer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.enum "field_type", enum_type: "field_type"
    t.index ["layer_id"], name: "index_fields_on_layer_id"
  end

  create_table "layers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.enum "geometry_type", enum_type: "layer_geometry_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "map_id", null: false
    t.jsonb "style", default: {}, null: false
    t.index ["map_id"], name: "index_layers_on_map_id"
  end

  create_table "maps", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.enum "role_type", null: false, enum_type: "role_type"
    t.uuid "user_id", null: false
    t.uuid "map_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["map_id"], name: "index_roles_on_map_id"
    t.index ["user_id"], name: "index_roles_on_user_id"
  end

  create_table "rows", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "values", default: {}, null: false
    t.uuid "layer_id"
    t.geometry "point", limit: {:srid=>4326, :type=>"st_point"}
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.geometry "polygon", limit: {:srid=>4326, :type=>"st_polygon"}
    t.geometry "line_string", limit: {:srid=>4326, :type=>"line_string"}
    t.uuid "territory_id"
    t.index ["layer_id"], name: "index_rows_on_layer_id"
    t.index ["territory_id"], name: "index_rows_on_territory_id"
    t.check_constraint "num_nonnulls(point, line_string, polygon, territory_id) = 1"
  end

  create_table "territories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.geometry "geometry", limit: {:srid=>4326, :type=>"multi_polygon"}
    t.uuid "territory_category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "code"
    t.uuid "parent_id"
    t.index ["code", "territory_category_id"], name: "index_territories_on_code_and_territory_category_id", unique: true
    t.index ["name"], name: "index_territories_on_name", opclass: :gin_trgm_ops, using: :gin
    t.index ["parent_id"], name: "index_territories_on_parent_id"
    t.index ["territory_category_id"], name: "index_territories_on_territory_category_id"
  end

  create_table "territory_categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "revision"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "revision"], name: "index_territory_categories_on_name_and_revision", unique: true
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.uuid "invited_by_id"
    t.integer "invitations_count", default: 0
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "fields", "layers"
  add_foreign_key "layers", "maps"
  add_foreign_key "roles", "maps"
  add_foreign_key "roles", "users"
  add_foreign_key "rows", "territories"
  add_foreign_key "territories", "territories", column: "parent_id"
  add_foreign_key "territories", "territory_categories"
  add_foreign_key "users", "users", column: "invited_by_id"
end
