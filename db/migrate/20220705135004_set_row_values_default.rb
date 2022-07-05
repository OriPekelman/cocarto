class SetRowValuesDefault < ActiveRecord::Migration[7.0]
  def change
    change_column_default :rows, :values, from: nil, to: {}

    up_only do
      Row.where(values: nil).update_all(values: {}) # rubocop:disable Rails/SkipsModelValidations
    end

    change_column_null :rows, :values, false
  end
end
