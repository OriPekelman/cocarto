# == Schema Information
#
# Table name: fields
#
#  id           :uuid             not null, primary key
#  enum_values  :string           is an Array
#  field_type   :enum             not null
#  label        :string
#  locked       :boolean          default(FALSE), not null
#  sort_order   :integer
#  text_is_long :boolean          default(FALSE), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  layer_id     :uuid             not null
#
# Indexes
#
#  index_fields_on_layer_id_and_sort_order  (layer_id,sort_order) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (layer_id => layers.id)
#
class Field < ApplicationRecord
  # Attributes
  enum :field_type, {text: "text", float: "float", integer: "integer", territory: "territory", date: "date", boolean: "boolean", css_property: "css_property", enum: "enum", files: "files"}, prefix: :type
  attr_readonly :field_type

  # Ordering
  include RankedModel
  ranks :sort_order, with_same: :layer_id
  attribute :sort_order, default: :last

  # Relations
  belongs_to :layer, touch: true
  has_and_belongs_to_many :territory_categories
  has_many :import_mappings, class_name: "Import::Mapping", inverse_of: :reimport_field, foreign_key: :reimport_field_id, dependent: :nullify

  # Validations
  validates :field_type, presence: true
  validates :text_is_long, inclusion: [true, false]
  validates :locked, inclusion: [true, false]

  # Type-specific validations
  validates :enum_values, presence: true, if: -> { type_enum? }

  # Hooks
  after_create_commit -> do
    broadcast_i18n_before_to layer.map, target: dom_id(layer, :new_field)
    layer.rows.each do |row|
      content = ApplicationController.render(FieldValueComponent.new(field: self, value: nil, row: row, form_prefix: :inline_form), layout: false)
      html = ApplicationController.render(FieldTdComponent.new(field: self).with_content(content), layout: false)
      broadcast_i18n_before_to(layer.map, target: dom_id(row, "actions"), html: html)
    end
  end

  after_update_commit -> do
    broadcast_i18n_replace_to layer.map
    needs_rows_broadcast = type_enum? && enum_values_previously_changed? || type_text? && text_is_long_previously_changed?
    if needs_rows_broadcast
      # issue #200: update all the rows so that the <select> options reflect the available enum values.
      layer.rows_with_fields_values.each do |row|
        content = ApplicationController.render(FieldValueComponent.new(field: self, value: row.fields_values[self], row: row, form_prefix: :inline_form), layout: false)
        html = ApplicationController.render(FieldTdComponent.new(field: self).with_content(content), layout: false)
        target = "##{dom_id(row)} .#{dom_id(self)}"
        # note: we need to use the `targets:` param when using `replace_to` to a css selector.
        broadcast_i18n_replace_to(layer.map, target: nil, targets: target, html: html)
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
    elsif type_files?
      value.is_a?(Array) ? value : nil
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
    case field_type
    when "integer"
      layer.rows.sum(Arel.sql("(values->>'#{id}')::integer"))
    when "float"
      layer.rows.sum(Arel.sql("(values->>'#{id}')::float"))
    when "boolean"
      layer.rows.where("(values->>'#{id}')::bool").size
    end
  end

  # Can this field have multiple values (array, attached files…)
  def multiple? = type_files?

  include FieldValuesAssociations::AssociationName
end
