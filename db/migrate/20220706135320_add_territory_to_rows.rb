class AddTerritoryToRows < ActiveRecord::Migration[7.0]
  def change
    add_reference :rows, :territory, foreign_key: true, type: :uuid
    add_enum_value :layer_geometry_type, "territory"
  end
end
