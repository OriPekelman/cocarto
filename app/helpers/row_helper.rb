module RowHelper
  def row_tr(row, extra_class)
    data_attributes = {
      controller: "row",
      row_lng_min_value: row.geo_lng_min,
      row_lat_min_value: row.geo_lat_min,
      row_lng_max_value: row.geo_lng_max,
      row_lat_max_value: row.geo_lat_max,
      row_properties_value: row.css_properties,
      action: "focusin->map#highlightFeatures"
    }

    tag.tr id: dom_id(row), data: data_attributes, class: class_names("row", extra_class) do
      row_tag_calculated_data(row) +
        row_tag_data_cols(row) +
        row_tag_actions(row)
    end
  end

  private

  def row_tag_calculated_data(row)
    case row.layer.geometry_type
    when "territory"
      tag.td(render("territories/search_form", form: dom_id(row, :form), field: "row[territory_id]", territory: row.territory), class: "calculated") +
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
    safe_join(row.fields_values.map { |field, value| field_td(field, value, dom_id(row, :form), row.author_id) })
  end

  def row_tag_actions(row)
    remove = button_to([row.layer, row], method: :delete, form: {data: {"turbo-confirm": t("common.confirm")}}) do
      embedded_svg("remove_item.svg")
    end
    tag.td(id: dom_id(row, "actions")) do
      tag.div(class: "actions") do
        row_tag_form(row) +
          remove +
          button_with_icon("", "center.svg", class: "small-icon", data: {action: "click->map#centerToRow"})
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
