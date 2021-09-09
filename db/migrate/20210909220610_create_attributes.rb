class CreateAttributes < ActiveRecord::Migration[6.1]
  def change
    create_enum :attribute_type, %w[text float integer]
    create_table :attributes, id: :uuid do |t|
      t.string :label
      t.references :table, type: :uuid, foreign_key: true
      t.enum :geography_type, enum_name: :attribute_type

      t.timestamps
    end
  end
end
