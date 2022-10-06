class ActiveRecordDoctoring < ActiveRecord::Migration[7.0]
  def change
    # We have an index on ["access_group_id", "user_id"]
    remove_index :access_groups_users, :access_group_id

    # All these references are actually required
    change_column_null :rows, :layer_id, false
    change_column_null :rows, :author_id, false
    change_column_null :fields, :layer_id, false
  end
end
