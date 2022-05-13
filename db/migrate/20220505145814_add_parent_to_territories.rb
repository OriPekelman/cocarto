class AddParentToTerritories < ActiveRecord::Migration[7.0]
  def change
    add_belongs_to :territories, :parent, foreign_key: {to_table: :territories}, type: :uuid
  end
end
