class CreatePoints < ActiveRecord::Migration[6.1]
  def change
    create_table :points, id: :uuid do |t|
      t.st_point :geog, geography: true
      t.references :table, null: false, foreign_key: true, type: :uuid
      t.integer :revision
      t.jsonb :attributes

      t.timestamps
    end
  end
end
