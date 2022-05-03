class CreateTerritoryCategories < ActiveRecord::Migration[7.0]
  def change
    create_table :territory_categories, id: :uuid do |t|
      t.string :name
      t.string :revision

      t.timestamps
    end
  end
end
