class CreateCommunes < ActiveRecord::Migration[7.0]
  def change
    create_table :communes, id: :uuid do |t|
      t.string :code
      t.string :libelle
      t.integer :year
      t.references :departement, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
