class DropAccessGroups < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key "access_groups", "maps"
    remove_foreign_key "access_groups_users", "access_groups"
    remove_foreign_key "access_groups_users", "users"

    drop_table "access_groups_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "access_group_id"
      t.uuid "user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["access_group_id", "user_id"], name: "index_access_groups_users_on_access_group_id_and_user_id", unique: true
      t.index ["user_id"], name: "index_access_groups_users_on_user_id"
    end

    drop_table "access_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.enum "role_type", null: false, enum_type: "role_type"
      t.uuid "map_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.text "token"
      t.text "name"
      t.index ["map_id"], name: "index_access_groups_on_map_id"
      t.index ["token"], name: "index_access_groups_on_token", unique: true
    end

    up_only do
      User.where(email: nil).destroy_all
    end

    change_column_null :users, :email, false
  end
end
