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
  include ActionView::RecordIdentifier # to access `dom_id`
  belongs_to :layer
  enum :field_type, {text: "text", float: "float", integer: "integer", territory: "territory", date: "date", boolean: "boolean"}

  after_create_commit -> do
    broadcast_before_to layer, target: "delete-column", partial: "fields/th"
    layer.rows.each do |row|
      broadcast_before_to layer, target: dom_id(row, :last), partial: "fields/field_in_form", locals: {field: self, form_id: dom_id(row, :form), value: nil}
      broadcast_replace_to layer, target: "tutorial", partial: "layers/tooltip", object: layer
    end
  end

  after_destroy_commit -> do
    broadcast_remove_to layer
    Turbo::StreamsChannel.broadcast_remove_to layer, targets: ".field-#{id}"
  end

  def numerical? = float? || integer?
end
