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
#  layer_id    :uuid             not null
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
  # Attributes
  enum :field_type, {text: "text", float: "float", integer: "integer", territory: "territory", date: "date", boolean: "boolean", css_property: "css_property", enum: "enum"}, prefix: :type
  attr_readonly :field_type

  # Relations
  belongs_to :layer
  has_and_belongs_to_many :territory_categories

  # Validations
  validates :field_type, presence: true

  # Type-specific validations
  validates :enum_values, presence: true, if: -> { type_enum? }

  # Hooks
  after_create_commit -> do
    broadcast_i18n_before_to layer.map, target: dom_id(layer, :new_field)
    layer.rows.each do |row|
      broadcast_i18n_before_to layer.map, target: dom_id(row, "actions"), partial: "fields/td", locals: {field: self, value: nil, form_id: dom_id(row, :form), author_id: row.author_id}
    end
  end

  after_update_commit -> do
    broadcast_i18n_replace_to layer.map
    if type_enum? && enum_values_previously_changed?
      # issue #200: update all the rows so that the <select> options reflect the available enum values.
      layer.rows.each do |row|
        target = "##{dom_id(row)} .#{dom_id(self)}"
        # note: we need to use the `targets:` param when using `replace_to` to a css selector.
        broadcast_i18n_replace_to layer.map, target: nil, targets: target, partial: "fields/td", locals: {field: self, value: nil, form_id: dom_id(row, :form), author_id: row.author_id}
      end
    end
  end

  after_destroy_commit -> do
    broadcast_remove_to layer.map
    Turbo::StreamsChannel.broadcast_remove_to layer.map, targets: ".#{dom_id(self)}"
  end

  # Type-specific coercion
  def enum_values=(new_values)
    super(new_values&.compact_blank&.uniq)
  end

  def territory_categories=(categories)
    super(TerritoryCategory.find(categories&.compact_blank))
  end
end
