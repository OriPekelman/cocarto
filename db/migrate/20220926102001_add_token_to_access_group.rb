class AddTokenToAccessGroup < ActiveRecord::Migration[7.0]
  def change
    add_column :access_groups, :token, :text
    add_column :access_groups, :name, :text

    # We accept null emails because a user will be created when using a shared link
    change_column_null :users, :email, true

    add_index(:access_groups_users, [:access_group_id, :user_id], unique: true)
  end
end
