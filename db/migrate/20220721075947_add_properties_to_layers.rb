class AddPropertiesToLayers < ActiveRecord::Migration[7.0]
  def change
    # This is table for a has_and_belong_to_many, so we don’t need timestamps
    create_table :layers_territory_categories, id: false do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.references :layer, foreign_key: true, type: :uuid
      t.references :territory_category, foreign_key: true, type: :uuid
    end
  end
end
