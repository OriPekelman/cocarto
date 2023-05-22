class AddIndexToAccessGroupsToken < ActiveRecord::Migration[7.0]
  def change
    add_index :access_groups, :token, unique: true
  end
end
