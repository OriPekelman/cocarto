class CreateDepartements < ActiveRecord::Migration[7.0]
  def change
    create_table :departements, id: :uuid do |t|
      t.string :code
      t.string :libelle

      t.timestamps
    end
  end
end
