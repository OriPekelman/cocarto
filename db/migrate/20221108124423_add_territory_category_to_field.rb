class AddTerritoryCategoryToField < ActiveRecord::Migration[7.0]
  def change
    create_table :fields_territory_categories do |t|
      t.timestamps
      t.references :field, index: true, foreign_key: true, type: :uuid
      t.references :territory_category, index: true, foreign_key: true, type: :uuid
    end
    up_only do
      execute <<-SQL.squish
        INSERT into fields_territory_categories(field_id, territory_category_id, created_at, updated_at)
          SELECT fields.id, territory_categories.id, fields.created_at, fields.updated_at
          FROM fields, territory_categories
          WHERE field_type='territory'
      SQL
    end
  end
end
