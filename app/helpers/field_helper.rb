module FieldHelper
  def field_tag(field, field_name, value, opts = {})
    case field.field_type
    when "integer"
      number_field_tag field_name, value, opts.merge(class: "numerical", step: "1")
    when "float"
      number_field_tag field_name, value, opts.merge(class: "numerical", step: "any")
    when "territory"
      render "territories/search", opts.merge(territory: value, field: field_name, field_id: field.id)
    when "date"
      date_field_tag field_name, value, opts
    when "boolean"
      check_box_tag field_name, "1", value == "1", opts
    when "enum"
      select_tag field_name, options_for_select(field.enum_values, value), opts.merge(include_blank: true)
    else
      text_field_tag field_name, value, opts.merge(class: "input")
    end
  end

  def field_td(field, value, form_id, author_id)
    # renders one form field tag for a value of a row for a specific field
    opts = {
      data: {action: "input->row#setDirty focusout->row#save"},
      form: form_id,
      autocomplete: :off
    }
    field_name = "row[fields_values][#{field.id}]"

    tag.td(field_tag(field, field_name, value, opts),
      class: class_names("table-field", dom_id(field)),
      data: {
        restricted_target: "restricted",
        restricted_authorizations: %W[owner editor contributor-#{author_id}].to_json # cf RowPolicy#update?
      })
  end
end
