# == Schema Information
#
# Table name: fields
#
#  id         :uuid             not null, primary key
#  field_type :enum
#  label      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  layer_id   :uuid
#
# Indexes
#
#  index_fields_on_layer_id  (layer_id)
#
# Foreign Keys
#
#  fk_rails_...  (layer_id => layers.id)
#
class Field < ApplicationRecord
  belongs_to :layer
  enum enum_field_type: {text: :text, float: :float, integer: :integer, territory: :territory, date: :date}
  validates :field_type, inclusion: {in: enum_field_types.keys}

  after_create_commit -> do
    broadcast_before_to layer, target: "delete-column", partial: "fields/th"
    layer.rows.each do |row|
      target = [row.id, "action"].join("-")
      broadcast_before_to layer, target: target, partial: "fields/field_in_form", locals: {field: self, row_id: row.id, value: nil}
      broadcast_replace_to layer, target: "tutorial", partial: "layers/tooltip", locals: {layer: layer}
    end
  end

  after_destroy_commit -> do
    broadcast_remove_to layer
    Turbo::StreamsChannel.broadcast_remove_to layer, targets: ".field-#{id}"
  end

  def numerical?
    ["float", "integer"].include?(field_type)
  end
end
