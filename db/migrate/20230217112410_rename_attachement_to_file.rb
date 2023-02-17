class RenameAttachementToFile < ActiveRecord::Migration[7.0]
  def change
    rename_enum_value :field_type, "attachment", "files"
  end
end
