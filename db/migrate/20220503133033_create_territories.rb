class CreateTerritories < ActiveRecord::Migration[7.0]
  def change
    create_table :territories, id: :uuid do |t|
      t.string :name
      t.st_polygon :geography, geographic: true
      t.references :territory_category, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
