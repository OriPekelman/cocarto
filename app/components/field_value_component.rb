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
      full_name = "#{dom_id(@row)}-#{field_name}"
      label_tag full_name do
        check_box_tag field_name, "1", @value, opts.merge(id: sanitize_to_id(full_name))
      end
    when "enum"
      select_tag field_name, options_for_select(@field.enum_values, @value), opts.merge(include_blank: true)
    when "files"
      name = @value.present? ? Row.human_attribute_name(:files, count: @value.length) : t("common.ellipsis")
      link_to name,
        edit_layer_row_path(@row.layer_id, @row.id, field_id: @field.id),
        data: {turbo_frame: "modal"},
        title: t("field.attachments"),
        class: "layer-table-td__files-button"
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
