class AddFulltextSearchOnTerritories < ActiveRecord::Migration[7.0]
  def up
    execute "create extension if not exists pg_trgm;"

    # We don’t remove the pg_trgm extension in a down, as it can be very tricky
    # Sometimes we don’t have the permissions to do so
  end

  def change
    add_index :territories, :name, using: :gin, opclass: {name: :gin_trgm_ops}
  end
end
