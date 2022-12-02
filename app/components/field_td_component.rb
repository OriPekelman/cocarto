# frozen_string_literal: true

class FieldTdComponent < ViewComponent::Base
  def initialize(field:, value:, form_id:, author_id:)
    @field = field
    @value = value
    @form_id = form_id
    @author_id = author_id
  end

  private
  def html_class
    class_names("table-field", dom_id(@field))
  end

  def authorizations
    %W[owner editor contributor-#{@author_id}].to_json # cf RowPolicy#update?
  end

  def opts
    {
      data: {action: "input->row#setDirty focusout->row#save"},
      form: @form_id,
      autocomplete: :off
    }
  end

  def field_name
    "row[fields_values][#{@field.id}]"
  end

  def field_tag
    case @field.field_type
    when "integer"
      number_field_tag field_name, @value, opts.merge(class: "numerical", step: "1")
    when "float"
      number_field_tag field_name, @value, opts.merge(class: "numerical", step: "any")
    when "territory"
      render SearchComponent.new(field: field_name, territory: @value, form: opts[:form], field_id: @field.id, layer_id: nil)
    when "date"
      date_field_tag field_name, @value, opts
    when "boolean"
      check_box_tag field_name, "1", @value == "1", opts
    when "enum"
      select_tag field_name, options_for_select(@field.enum_values, @value), opts.merge(include_blank: true)
    else
      text_field_tag field_name, @value, opts.merge(class: "input")
    end
  end
end
