# frozen_string_literal: true

class RowComponent < ViewComponent::Base
  def initialize(row:, extra_class: "")
    @row = row
    @extra_class = extra_class
  end

  private

  def classes
    class_names("row", @extra_class)
  end

  def row_tag_calculated_data(row)
    case row.layer.geometry_type
    when "territory"
      tag.td(render(SearchComponent.new(form: dom_id(row, :form), field: "row[territory_id]", territory: row.territory, field_id: nil, layer_id: row.layer_id), class: "calculated")) +
        tag.td(row.territory.code, class: "calculated")
    when "point"
      tag.td(number_with_precision(row.geo_lng_min, precision: 6), class: "numerical calculated") +
        tag.td(number_with_precision(row.geo_lat_min, precision: 6), class: "numerical calculated")
    when "line_string"
      tag.td(number_to_human(row.geo_length, units: :length), class: "numerical calculated")
    when "polygon"
      tag.td(number_to_human(row.geo_area, units: :area), class: "numerical calculated")
    end
  end

  def row_tag_data_cols(row)
    safe_join(row.fields_values.map { |field, value|
      render FieldTdComponent.new(field: field, value: value, form_id: dom_id(row, :form), author_id: row.author_id)
    })
  end

  def row_tag_actions(row)
    remove = button_to([row.layer, row], method: :delete, title: t("layers.layer.delete_row"), form: {data: {"turbo-confirm": t("common.confirm")}}) do
      helpers.embedded_svg("remove_item.svg", class: "icon--sm")
    end
    tag.td(id: dom_id(row, "actions"), class: "table-actions") do
      tag.div(class: "table-actions__container") do
        row_tag_form(row) +
          remove +
          button_tag(data: {action: "click->map#centerToRow"}, title: t("layers.layer.center_on_row")) do
            helpers.embedded_svg("center.svg", class: "icon--sm")
          end
      end
    end
  end

  def row_tag_form(row)
    form_with method: :patch, model: [row.layer, row], id: dom_id(row, :form), data: {row_target: "form", action: "row#save"} do |form|
      row_tag_geojson(row, form) +
        form.button("save", class: "is-hidden")
    end
  end

  def row_tag_geojson(row, form)
    # If our layer is a territory, we need the geojson for display
    # but we don’t want it in the from
    if !row.layer.geometry_territory?
      form.hidden_field "geojson", data: {row_target: "geojson"}
    else
      hidden_field_tag "geojson", row.territory.geojson, data: {row_target: "geojson"}
    end
  end
end
