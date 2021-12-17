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

ActiveRecord::Schema.define(version: 2021_12_10_114047) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "postgis"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "fields_type_enum", ["text", "float", "integer"]
  create_enum "geometry_type_enum", ["point", "linestring", "polygon"]

  create_enum :fields_type_enum, [
    "text",
    "float",
    "integer",
  ], force: :cascade

  create_enum :geometry_type_enum, [
    "point",
    "linestring",
    "polygon",
  ], force: :cascade

  create_table "fields", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "label"
    t.uuid "layer_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.enum "field_type", enum_type: "fields_type_enum", enum_name: "fields_type_enum"
    t.index ["layer_id"], name: "index_fields_on_layer_id"
  end

  create_table "layers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.enum "geometry_type", enum_type: "geometry_type_enum", enum_name: "geometry_type_enum"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "points", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.geometry "geog", limit: {:srid=>0, :type=>"st_point"}
    t.uuid "layer_id", null: false
    t.integer "revision"
    t.jsonb "fields"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "row_content_type"
    t.index ["layer_id"], name: "index_points_on_layer_id"
  end

  create_table "row_contents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "values"
    t.uuid "layer_id"
    t.string "geometry_type", null: false
    t.uuid "geometry_id", null: false
    t.index ["geometry_type", "geometry_id"], name: "index_row_contents_on_geometry"
    t.index ["layer_id"], name: "index_row_contents_on_layer_id"
  end

  add_foreign_key "fields", "layers"
  add_foreign_key "points", "layers"
end
