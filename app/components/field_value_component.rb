# frozen_string_literal: true

class FieldValueComponent < ViewComponent::Base
  def initialize(field:, value:, row:, form_prefix:, autofocus: false)
    @field = field
    @value = value
    @row = row
    @form_prefix = form_prefix # form_prefix is needed to differentiate the inline form (in RowComponent) and the regular edit (in rows/_form). cf #196
    @autofocus = autofocus
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
      full_name = "#{dom_id(@row)}-#{field_name}"
      label_tag full_name do
        hidden_field = hidden_field_tag(field_name, "0", opts) # needed to allow unchecking checkboxes, see #338
        check_box = check_box_tag(field_name, "1", @value, opts.merge(id: sanitize_to_id(full_name)))
        hidden_field + check_box
      end
    when "enum"
      select_tag field_name, options_for_select(@field.enum_values, @value), opts.merge(include_blank: true)
    when "files"
      if @form_prefix == :inline_form
        name = @value.present? ? Row.human_attribute_name(:files, count: @value.length) : ""
        link_to name,
          edit_row_path(@row.id, focus_field_id: @field.id),
          data: {turbo_frame: "modal", restricted_target: "restricted", restricted_authorizations: RowPolicy.authorizations(@row)},
          title: t("field.attachments"),
          class: "layer-table-td__button"
      else
        render FileFieldComponent.new(field: @field, row: @row)
      end
    when "text"
      if @field.text_is_long?
        if @form_prefix == :inline_form
          link_to @value&.truncate_words(4, omission: "…") || "",
            edit_row_path(@row.id, focus_field_id: @field.id),
            data: {turbo_frame: "modal", restricted_target: "restricted", restricted_authorizations: RowPolicy.authorizations(@row)},
            title: t("common.edit"),
            class: "layer-table-td__button"
        else
          text_area_tag field_name, @value, opts.merge(class: "input")
        end
      else
        text_field_tag field_name, @value, opts.merge(class: "input")
      end
    else
      text_field_tag field_name, @value, opts.merge(class: "input")
    end
  end

  private

  def opts
    autosave = @field.field_type.in? %w[boolean enum] # checkboxes and selects are saved immediately
    action = autosave ? "row#save" : "row#setDirty focusout->row#save"

    {
      data: {
        action: action,
        row_autosave_param: autosave,
        restricted_target: "restricted",
        restricted_authorizations: @field.locked? ? %W[locked].to_json : RowPolicy.authorizations(@row)
      },
      form: dom_id(@row, @form_prefix),
      autocomplete: :off,
      autofocus: @autofocus
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
