class RemoveUserFromLayer < ActiveRecord::Migration[7.0]
  def up
    remove_reference :layers, :user
  end

  def down
    add_reference :layers, :user, foreign_key: true, type: :uuid
    Layer.includes(:map).all.each do |layer|
      layer.update(user_id: layer.map.user_id)
    end
    change_column_null :layers, :map_id, false
  end
end
