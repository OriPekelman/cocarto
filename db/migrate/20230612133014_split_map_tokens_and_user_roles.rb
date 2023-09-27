class SplitMapTokensAndUserRoles < ActiveRecord::Migration[7.0]
  def change
    change_column_null :rows, :author_id, true
    add_column :rows, :anonymous_tag, :string
    add_index :rows, :anonymous_tag

    create_table :map_tokens, id: :uuid do |t|
      t.enum :role_type, null: false, enum_type: :role_type
      t.belongs_to :map, type: :uuid, null: false, foreign_key: true
      t.text :name, null: false
      t.text :token, null: false
      t.integer :access_count, null: false, default: 0

      t.timestamps
      t.index :token, unique: true
    end

    create_table :user_roles, id: :uuid do |t|
      t.enum "role_type", null: false, enum_type: "role_type"
      t.belongs_to :map, type: :uuid, null: false, index: false, foreign_key: true
      t.belongs_to :user, type: :uuid, null: false, foreign_key: true
      t.belongs_to :map_token, type: :uuid, null: true, foreign_key: true

      t.timestamps
      t.index [:map_id, :user_id], unique: true
    end

    up_only do
      AccessGroup.includes(:map, :users).where(token: nil).find_each do |group|
        UserRole.create!(map: group.map, role_type: group.role_type, user: group.users[0])
      end

      AccessGroup.includes(:map, :users).where.not(token: nil).find_each do |group|
        MapToken.create!(map: group.map, role_type: group.role_type, name: group.name, token: group.token, access_count: group.users.count)
      end
    end

    # Later:
    # User.where(email: nil).destroy_all
    # change_column_null :users, :email, false
    # drop_table :access_groups
    # drop_table :access_groups_users
  end
end
