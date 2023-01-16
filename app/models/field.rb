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
  belongs_to :layer, touch: true
  has_and_belongs_to_many :territory_categories

  # Validations
  validates :field_type, presence: true

  # Type-specific validations
  validates :enum_values, presence: true, if: -> { type_enum? }

  # Hooks
  after_create_commit -> do
    broadcast_i18n_before_to layer.map, target: dom_id(layer, :new_field)
    layer.rows.each do |row|
      td = FieldTdComponent.new(field: self, value: nil, form_id: dom_id(row, :form), author_id: row.author_id)
      broadcast_i18n_before_to(layer.map, target: dom_id(row, "actions"), html: ApplicationController.render(td, layout: false))
    end
  end

  after_update_commit -> do
    broadcast_i18n_replace_to layer.map
    if type_enum? && enum_values_previously_changed?
      # issue #200: update all the rows so that the <select> options reflect the available enum values.
      layer.rows.each do |row|
        td = FieldTdComponent.new(field: self, value: nil, form_id: dom_id(row, :form), author_id: row.author_id)
        target = "##{dom_id(row)} .#{dom_id(self)}"
        # note: we need to use the `targets:` param when using `replace_to` to a css selector.
        broadcast_i18n_replace_to(layer.map, target: nil, targets: target, html: ApplicationController.render(td, layout: false))
      end
    end
  end

  after_destroy_commit -> do
    return if layer.destroyed?

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

  # HTML only speaks in strings
  # It casts to its native representation
  def cast(value)
    if type_territory?
      Territory.exists?(id: value) ? value : nil
    elsif type_css_property? && label == "stroke-width"
      ActiveModel::Type.lookup(:integer).cast(value)
    elsif active_model
      active_model.cast(value)
    else
      value
    end
  end

  def active_model
    active_model_type = {
      "text" => :string,
      "float" => :float,
      "integer" => :integer,
      "date" => :date,
      "boolean" => :boolean
    }[field_type]

    ActiveModel::Type.lookup(active_model_type) if active_model_type
  end

  def sum
    if type_integer? || type_float?
      layer.rows.sum(Arel.sql("(values->>'#{id}')::numeric"))
    elsif type_boolean?
      layer.rows.where("(values->>'#{id}')::bool").length
    end
  end

  include FieldValuesAssociations::AssociationName
end
