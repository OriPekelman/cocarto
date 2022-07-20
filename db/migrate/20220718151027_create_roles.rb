class CreateRoles < ActiveRecord::Migration[7.0]
  def change
    create_enum :role_type, %i[owner editor contributor viewer]
    create_table :roles, id: :uuid do |t|
      t.enum :role_type, enum_type: :role_type, null: false
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :map, null: false, foreign_key: true, type: :uuid
      t.timestamps
    end

    up_only do
      Map.find_each do |map|
        map.roles.create(user_id: map.user_id, role_type: :owner)
      end
    end

    remove_reference :maps, :user # this makes this migration non revertable :)
  end
end
