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

ActiveRecord::Schema[7.0].define(version: 2023_06_29_085044) do
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
    "css_property",
    "enum",
    "files",
  ], force: :cascade

  create_enum :import_operation_status, [
    "ready",
    "fetching",
    "importing",
    "done",
  ], force: :cascade

  create_enum :import_source_type, [
    "random",
    "csv",
    "geojson",
    "wfs",
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

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "fields", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "label"
    t.uuid "layer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.enum "field_type", null: false, enum_type: "field_type"
    t.string "enum_values", array: true
    t.index ["layer_id"], name: "index_fields_on_layer_id"
  end

  create_table "fields_territory_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "field_id"
    t.uuid "territory_category_id"
    t.index ["field_id"], name: "index_fields_territory_categories_on_field_id"
    t.index ["territory_category_id"], name: "index_fields_territory_categories_on_territory_category_id"
  end

  create_table "import_configurations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "map_id", null: false
    t.string "name"
    t.enum "source_type", null: false, enum_type: "import_source_type"
    t.string "remote_source_url"
    t.string "source_text_encoding"
    t.string "source_csv_column_separator"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["map_id"], name: "index_import_configurations_on_map_id"
  end

  create_table "import_mappings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "configuration_id", null: false
    t.uuid "layer_id", null: false
    t.string "source_layer_name"
    t.boolean "bulk_mode", default: false, null: false
    t.boolean "ignore_empty_geometry_rows", default: true, null: false
    t.string "geometry_encoding_format"
    t.string "geometry_columns", array: true
    t.integer "geometry_srid"
    t.jsonb "fields_columns"
    t.uuid "reimport_field_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["configuration_id"], name: "index_import_mappings_on_configuration_id"
    t.index ["layer_id"], name: "index_import_mappings_on_layer_id"
    t.index ["reimport_field_id"], name: "index_import_mappings_on_reimport_field_id"
  end

  create_table "import_operations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "configuration_id", null: false
    t.string "remote_source_url"
    t.enum "status", default: "ready", null: false, enum_type: "import_operation_status"
    t.string "global_error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["configuration_id"], name: "index_import_operations_on_configuration_id"
  end

  create_table "import_reports", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "operation_id", null: false
    t.uuid "mapping_id", null: false
    t.string "row_results"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mapping_id"], name: "index_import_reports_on_mapping_id"
    t.index ["operation_id"], name: "index_import_reports_on_operation_id"
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

  create_table "layers_territory_categories", id: false, force: :cascade do |t|
    t.uuid "layer_id"
    t.uuid "territory_category_id"
    t.index ["layer_id"], name: "index_layers_territory_categories_on_layer_id"
    t.index ["territory_category_id"], name: "index_layers_territory_categories_on_territory_category_id"
  end

  create_table "map_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.enum "role_type", null: false, enum_type: "role_type"
    t.uuid "map_id", null: false
    t.text "name", null: false
    t.text "token", null: false
    t.integer "access_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["map_id"], name: "index_map_tokens_on_map_id"
    t.index ["token"], name: "index_map_tokens_on_token", unique: true
  end

  create_table "maps", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "default_latitude"
    t.float "default_longitude"
    t.float "default_zoom"
  end

  create_table "rows", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "values", default: {}, null: false
    t.uuid "layer_id", null: false
    t.geometry "point", limit: {:srid=>4326, :type=>"st_point"}
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.geometry "polygon", limit: {:srid=>4326, :type=>"st_polygon"}
    t.geometry "line_string", limit: {:srid=>4326, :type=>"line_string"}
    t.uuid "territory_id"
    t.uuid "author_id"
    t.virtual "geojson", type: :text, as: "st_asgeojson(COALESCE(point, line_string, polygon))", stored: true
    t.virtual "geo_lng_min", type: :decimal, as: "st_xmin((COALESCE(point, line_string, polygon))::box3d)", stored: true
    t.virtual "geo_lat_min", type: :decimal, as: "st_ymin((COALESCE(point, line_string, polygon))::box3d)", stored: true
    t.virtual "geo_lng_max", type: :decimal, as: "st_xmax((COALESCE(point, line_string, polygon))::box3d)", stored: true
    t.virtual "geo_lat_max", type: :decimal, as: "st_ymax((COALESCE(point, line_string, polygon))::box3d)", stored: true
    t.virtual "geo_length", type: :decimal, as: "st_length((line_string)::geography)", stored: true
    t.virtual "geo_area", type: :decimal, as: "st_area((polygon)::geography)", stored: true
    t.virtual "geom_web_mercator", type: :geometry, limit: {:srid=>0, :type=>"geometry"}, as: "st_transform(COALESCE(point, line_string, polygon), 3857)", stored: true
    t.bigserial "feature_id", null: false
    t.string "anonymous_tag"
    t.index ["anonymous_tag"], name: "index_rows_on_anonymous_tag"
    t.index ["author_id"], name: "index_rows_on_author_id"
    t.index ["created_at"], name: "index_rows_on_created_at"
    t.index ["geom_web_mercator"], name: "index_rows_on_geom_web_mercator", using: :gist
    t.index ["layer_id", "feature_id"], name: "index_rows_on_layer_id_and_feature_id", unique: true
    t.index ["territory_id"], name: "index_rows_on_territory_id"
    t.index ["updated_at"], name: "index_rows_on_updated_at"
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
    t.virtual "geojson", type: :text, as: "st_asgeojson(geometry)", stored: true
    t.virtual "geo_lng_min", type: :decimal, as: "st_xmin((geometry)::box3d)", stored: true
    t.virtual "geo_lat_min", type: :decimal, as: "st_ymin((geometry)::box3d)", stored: true
    t.virtual "geo_lng_max", type: :decimal, as: "st_xmax((geometry)::box3d)", stored: true
    t.virtual "geo_lat_max", type: :decimal, as: "st_ymax((geometry)::box3d)", stored: true
    t.virtual "geo_area", type: :decimal, as: "st_area((geometry)::geography)", stored: true
    t.virtual "geom_web_mercator", type: :geometry, limit: {:srid=>0, :type=>"geometry"}, as: "st_transform(geometry, 3857)", stored: true
    t.index ["code", "territory_category_id"], name: "index_territories_on_code_and_territory_category_id", unique: true
    t.index ["geom_web_mercator"], name: "index_territories_on_geom_web_mercator", using: :gist
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

  create_table "user_roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.enum "role_type", null: false, enum_type: "role_type"
    t.uuid "map_id", null: false
    t.uuid "user_id", null: false
    t.uuid "map_token_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["map_id", "user_id"], name: "index_user_roles_on_map_id_and_user_id", unique: true
    t.index ["map_token_id"], name: "index_user_roles_on_map_token_id"
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", null: false
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "fields", "layers"
  add_foreign_key "fields_territory_categories", "fields"
  add_foreign_key "fields_territory_categories", "territory_categories"
  add_foreign_key "import_configurations", "maps"
  add_foreign_key "import_mappings", "fields", column: "reimport_field_id"
  add_foreign_key "import_mappings", "import_configurations", column: "configuration_id"
  add_foreign_key "import_mappings", "layers"
  add_foreign_key "import_operations", "import_configurations", column: "configuration_id"
  add_foreign_key "import_reports", "import_mappings", column: "mapping_id"
  add_foreign_key "import_reports", "import_operations", column: "operation_id"
  add_foreign_key "layers", "maps"
  add_foreign_key "layers_territory_categories", "layers"
  add_foreign_key "layers_territory_categories", "territory_categories"
  add_foreign_key "map_tokens", "maps"
  add_foreign_key "rows", "layers"
  add_foreign_key "rows", "territories"
  add_foreign_key "rows", "users", column: "author_id"
  add_foreign_key "territories", "territories", column: "parent_id"
  add_foreign_key "territories", "territory_categories"
  add_foreign_key "user_roles", "map_tokens"
  add_foreign_key "user_roles", "maps"
  add_foreign_key "user_roles", "users"
  add_foreign_key "users", "users", column: "invited_by_id"
end
