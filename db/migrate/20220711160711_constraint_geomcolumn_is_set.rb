class ConstraintGeomcolumnIsSet < ActiveRecord::Migration[7.0]
  def change
    add_check_constraint :rows, "num_nonnulls(point, line_string, polygon, territory_id) = 1"
  end
end
