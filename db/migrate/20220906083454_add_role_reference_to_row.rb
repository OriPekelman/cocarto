class AddRoleReferenceToRow < ActiveRecord::Migration[7.0]
  def change
    add_reference :rows, :author, type: :uuid
    up_only do
      Row.all.each do |row|
        row.author = row.layer.map.users.merge(Role.owner).first
        row.save
      end
    end
    add_foreign_key :rows, :users, column: :author_id
  end
end
