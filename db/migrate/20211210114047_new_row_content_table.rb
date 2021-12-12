class NewRowContentTable < ActiveRecord::Migration[6.1]
  def up
    create_table :row_contents, id: :uuid do |t|
      t.jsonb "values"
      t.belongs_to :layer, type: :uuid
      t.belongs_to :geometry, polymorphic: true, type: :uuid, null: false
    end

    Point.all.each do |p|
      RowContent.create(values: p.fields, layer_id: p.layer_id, geometry: p)
    end
  end

  def down
    drop_table :row_contents
  end
end
