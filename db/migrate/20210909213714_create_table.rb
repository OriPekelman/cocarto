class CreateTable < ActiveRecord::Migration[6.1]
  def change
    create_enum :product_type, %w[point linestring polygon]
    create_table :tables, id: :uuid do |t|
      t.string :name
      t.enum :geography_type, enum_name: :product_type

      t.timestamps
    end
  end
end
