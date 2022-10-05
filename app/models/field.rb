# == Schema Information
#
# Table name: fields
#
#  id          :uuid             not null, primary key
#  enum_values :string           is an Array
#  field_type  :enum             not null
#  label       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  layer_id    :uuid
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
  enum :field_type, {text: "text", float: "float", integer: "integer", territory: "territory", date: "date", boolean: "boolean", css_property: "css_property", enum: "enum"}, prefix: :type
  validates :field_type, presence: true

  validates :enum_values, presence: true, if: -> { type_enum? }

  after_create_commit -> do
    broadcast_i18n_before_to layer, target: "delete-column", partial: "fields/th"
    layer.rows.each do |row|
      broadcast_i18n_before_to layer, target: dom_id(row, :last), partial: "fields/td", locals: {field: self, value: nil, form_id: dom_id(row, :form), author_id: row.author_id}
    end
  end

  after_destroy_commit -> do
    broadcast_remove_to layer
    Turbo::StreamsChannel.broadcast_remove_to layer, targets: ".#{dom_id(self)}"
  end

  def numerical? = type_float? || type_integer?
end
