class CreateAccessGroups < ActiveRecord::Migration[7.0]
  def up
    rename_table :roles, :access_groups

    create_table :access_groups_users, id: :uuid do |t|
      t.references :access_group, index: true, foreign_key: true, type: :uuid
      t.references :user, index: true, foreign_key: true, type: :uuid
      t.timestamps
    end

    execute <<-SQL.squish
      INSERT INTO access_groups_users(access_group_id, user_id, created_at, updated_at)
        SELECT id, user_id, created_at, updated_at
        FROM access_groups
    SQL

    remove_column :access_groups, :user_id
  end

  def down
    rename_table :access_groups, :roles
    add_reference :roles, :user, index: true, foreign_key: true, type: :uuid

    execute <<-SQL.squish
    UPDATE roles
      SET user_id = access_groups_users.user_id
      FROM access_groups_users
      WHERE access_groups_users.access_group_id = roles.id
    SQL

    drop_table :access_groups_users
  end
end
