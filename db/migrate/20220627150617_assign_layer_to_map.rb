class AssignLayerToMap < ActiveRecord::Migration[7.0]
  def up
    add_reference :layers, :map, foreign_key: true, type: :uuid

    Layer.all.each do |layer|
      map = Map.create({user_id: layer.user_id, name: layer.name})
      layer.update(map_id: map.id)
    end

    change_column_null :layers, :map_id, false
  end

  def down
    remove_reference :layers, :map
  end
end
