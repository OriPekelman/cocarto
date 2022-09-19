module RowHelper
  def row_tag(row)
    data_attributes = {
      controller: "row",
      row_author_value: row.author_id,
      lng_min: row.lng_min,
      lat_min: row.lat_min,
      lng_max: row.lng_max,
      lat_max: row.lat_max
    }

    tag.tr id: dom_id(row), data: data_attributes do
      row_tag_calculated_data(row) +
        row_tag_data_cols(row) +
        row_tag_actions(row)
    end
  end

  private

  def row_tag_calculated_data(row)
    case row.layer.geometry_type
    when "territory"
      tag.td(render("territories/search_form", form: dom_id(row, :form), field: "row[territory_id]", territory: row.territory)) +
        tag.td(row.territory.code)
    when "point"
      tag.td(number_with_precision(row.geometry.x, precision: 6, class: "numerical")) +
        tag.td(number_with_precision(row.geometry.y, precision: 6, class: "numerical"))
    when "line_string"
      tag.td(number_to_human(row.length, units: :length, class: "numerical"))
    when "polygon"
      tag.td(number_to_human(row.area, units: :area, class: "numerical"))
    end
  end

  def row_tag_data_cols(row)
    safe_join(row.fields_values.map { |field, value| field_value field, value, dom_id(row, :form) })
  end

  def row_tag_actions(row)
    tag.td(id: dom_id(row, :last)) do
      tag.div(class: "actions") do
        row_tag_form(row) +
          button_to(t("helpers.link.row.delete"), [row.layer, row], method: :delete)
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