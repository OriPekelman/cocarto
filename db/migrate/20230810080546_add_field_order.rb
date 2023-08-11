class AddFieldOrder < ActiveRecord::Migration[7.0]
  def change
    add_column :fields, :sort_order, :integer

    up_only do
      Layer.all.each do |layer|
        layer.fields.order(:created_at).each_with_index do |field, index|
          field.update_column(:sort_order, index) # rubocop:disable Rails/SkipsModelValidations
        end
      end
    end

    add_index :fields, [:layer_id, :sort_order], unique: true
    # https://github.com/gregnavis/active_record_doctor#removing-extraneous-indexes
    remove_index :fields, :layer_id, name: "index_fields_on_layer_id"
  end
end
