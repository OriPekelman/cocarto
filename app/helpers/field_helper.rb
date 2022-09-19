module FieldHelper
  def field_value(field, value, form_id)
    # renders one form field tag for a value of a row for a specific field
    opts = {
      id: field.id,
      data: {action: "input->row#setDirty focusout->row#save"},
      form: form_id,
      autocomplete: :off
    }
    field_name = "row[fields_values][#{field.id}]"

    field_tag = case field.field_type
    when "integer"
      number_field_tag field_name, value, opts.merge(class: "numerical", step: "1")
    when "float"
      number_field_tag field_name, value, opts.merge(class: "numerical", step: "any")
    when "territory"
      render "territories/search_form", opts.merge(territory: value, field: field_name)
    when "date"
      date_field_tag field_name, value, opts
    when "boolean"
      check_box_tag field_name, "1", value == "1", opts
    else
      text_field_tag field_name, value, opts.merge(class: "input")
    end

    content_tag :td, field_tag, class: class_names("field-#{field.id}", numerical: field.numerical?)
  end
end
