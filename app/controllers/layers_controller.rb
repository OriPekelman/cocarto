require "securerandom"

class LayersController < ApplicationController
  before_action :access_by_apikey, only: %i[geojson]
  before_action :authenticate_user!
  before_action :set_layer, only: %i[show update destroy schema geojson]

  def show
    respond_to do |format|
      format.html { redirect_to map_path(@layer.map, params: {open: helpers.dom_id(@layer)}) }
      format.csv do
        exporter = ImportExport::Exporter.new(@layer)
        data = exporter.csv
        send_data data, filename: "#{@layer.name}.csv", type: "application/geo+json"
      end
    end
  end

  def new
    map = current_user.maps.find(params["map_id"])
    @layer = authorize map.layers.new
  end

  def create
    map = current_user.maps.find(layer_params["map_id"])

    layer = authorize map.layers.new(layer_params)
    if layer.save
      redirect_to layer
    else
      # This line overrides the default rendering behavior, which
      # would have been to render the "create" view.
      render "new", status: :unprocessable_entity
    end
  end

  def update
    if @layer.update(layer_params)
      @layer.broadcast_i18n_replace_to @layer.map
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to layer_path(@layer) }
      end
    else
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    @layer.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @layer.map, notice: t("helpers.message.layer.destroyed"), status: :see_other }
    end
  end

  def schema
    properties = @layer.fields.all.map { |f| field_schema(f) }.to_h

    render json: {
      type: :object,
      properties: properties
    }.to_json
  end

  def geojson
    data = Rails.cache.fetch([@layer, "geojson"]) do
      RGeo::GeoJSON.encode(@layer.geo_feature_collection).to_json
    end
    send_data data, filename: "#{@layer.name}.geojson", type: "application/geo+json"
  end

  private

  def set_layer
    @layer = authorize Layer.includes(:map, rows: :territory, fields: :territory_categories).find(params[:id])
  end

  def layer_params
    params.require(:layer).permit(:name, :geometry_type, :map_id, :color, territory_category_ids: [])
  end

  def field_schema(field)
    mapping = {
      "text" => :string,
      "float" => :number,
      "integer" => :integer
    }

    [field.id, type: mapping[field.field_type], title: field.label]
  end

  def access_by_apikey
    token = params["authkey"] || request.headers["X-Auth-Key"]
    if token.present? && !user_signed_in?
      access_group = AccessGroup.find_by(token: token)
      if access_group.present?
        headers["Access-Control-Allow-Origin"] = "*"
        headers["Access-Control-Allow-Methods"] = "GET OPTIONS"
        headers["Access-Control-Allow-Headers"] = "*"
        sign_in User.new(access_groups: [access_group], remember_me: false)
      else
        render plain: t("api.bad_key"), status: :unauthorized
      end
    end
  end
end
