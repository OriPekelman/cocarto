class DeleteCommunesDepartements < ActiveRecord::Migration[7.0]
  def up
    drop_table "communes"
    drop_table "departements"
  end

  def down
    create_table "communes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "code"
      t.string "libelle"
      t.integer "year"
      t.uuid "departement_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["departement_id"], name: "index_communes_on_departement_id"
    end

    create_table "departements", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "code"
      t.string "libelle"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
