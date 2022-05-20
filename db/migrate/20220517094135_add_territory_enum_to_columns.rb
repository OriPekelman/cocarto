class AddTerritoryEnumToColumns < ActiveRecord::Migration[7.0]
  def up
    execute "ALTER TYPE fields_type_enum ADD VALUE 'territory';"
  end

  def down
    # https://blog.yo1.dog/updating-enum-values-in-postgresql-the-safe-and-easy-way/
    execute <<-SQL
      ALTER TYPE fields_type_enum RENAME TO fields_type_enum_old;
      CREATE TYPE fields_type_enum AS ENUM('text', 'float', 'integer');
      ALTER TABLE fields ALTER COLUMN field_type TYPE fields_type_enum USING field_type::text::fields_type_enum;
      DROP TYPE fields_type_enum_old;
    SQL
  end
end
