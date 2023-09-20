class AddOperationStatusStarted < ActiveRecord::Migration[7.0]
  def change
    add_enum_value :import_operation_status, "started"
  end
end
