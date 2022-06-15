# == Schema Information
#
# Table name: rows
#
#  id         :uuid             not null, primary key
#  point      :geometry         point, 0
#  values     :jsonb
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  layer_id   :uuid
#
# Indexes
#
#  index_rows_on_layer_id  (layer_id)
#
class Row < ApplicationRecord
  belongs_to :layer
  after_update_commit -> { broadcast_replace_to layer }
  after_destroy_commit -> { broadcast_remove_to layer }
  after_create_commit -> do
    broadcast_append_to layer, target: "rows-tbody", partial: "rows/row", locals: {row: self}
    broadcast_replace_to layer, target: "tutorial", partial: "layers/tooltip", locals: {layer: layer}
  end
  # Iterates of each field with its data
  def data
    layer.fields.each do |field|
      value = values[field.id]
      if field.field_type == "territory" && !value.nil?
        value = Territory.find(value)
      end
      yield [field, value]
    end
  end
end