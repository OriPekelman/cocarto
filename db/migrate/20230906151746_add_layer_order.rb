class AddLayerOrder < ActiveRecord::Migration[7.0]
  def change
    add_column :layers, :sort_order, :integer

    up_only do
      Map.all.each do |map|
        map.layers.order(:created_at).each_with_index do |layer, index|
          layer.update_column(:sort_order, index) # rubocop:disable Rails/SkipsModelValidations
        end
      end
    end

    add_index :layers, [:map_id, :sort_order], unique: true
    # https://github.com/gregnavis/active_record_doctor#removing-extraneous-indexes
    remove_index :layers, :map_id, name: "index_layers_on_map_id"
  end
end
