class AddSpreadsheetSourceType < ActiveRecord::Migration[7.0]
  def change
    add_enum_value :import_source_type, "spreadsheet"
  end
end
