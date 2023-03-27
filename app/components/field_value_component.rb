# frozen_string_literal: true

class FieldValueComponent < ViewComponent::Base
  def initialize(field:, value:, row:)
    @field = field
    @value = value
    @row = row
  end

  def field_tag
    case @field.field_type
    when "integer"
      number_field_tag field_name, @value, opts.merge(step: "1")
    when "float"
      number_field_tag field_name, @value, opts.merge(step: "any")
    when "territory"
      render SearchComponent.new(field: field_name, territory: @value, form: opts[:form], field_id: @field.id, layer_id: nil)
    when "date"
      date_field_tag field_name, @value, opts
    when "boolean"
      # This is a temporary hack until the data is cleaned in the database
      # The task fix_data:fields_values_type will change "1" to `true`
      # Once the task ran, we can use only @value
      check_box_tag field_name, "1", @value == "1" || @value, opts
    when "enum"
      select_tag field_name, options_for_select(@field.enum_values, @value), opts.merge(include_blank: true)
    when "files"
      link_to Row.human_attribute_name(:files, count: @value.length),
        edit_layer_row_path(@row.layer_id, @row.id, field_id: @field.id),
        data: {turbo_frame: "modal"},
        class: "button button--slim button--link"
    else
      text_field_tag field_name, @value, opts.merge(class: "input")
    end
  end

  private

  def opts
    {
      data: {
        action: "input->row#setDirty focusout->row#save",
        restricted_target: "restricted",
        restricted_authorizations: RowPolicy.authorizations(@row)
      },
      form: dom_id(@row, :form),
      autocomplete: :off
    }
  end

  def field_name
    if @field.multiple?
      "row[fields_values][#{@field.id}][]"
    else
      "row[fields_values][#{@field.id}]"
    end
  end
end
