class FixPointType < ActiveRecord::Migration[7.0]
  def up
    change_column :rows, :point, :st_point, srid: 4326
  end

  def down
    change_column :rows, :point, :st_point, srid: 0
  end
end
