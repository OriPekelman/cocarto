require "securerandom"

class LayersController < ApplicationController
  before_action :access_by_apikey, only: %i[geojson]
  before_action :set_layer, only: %i[show update destroy schema geojson]
  before_action :authenticate_user!

  def show
    @role_type = current_user.access_groups.find_by(map: @layer.map)&.role_type
  end

  def new
    map = current_user.maps.find(params["map_id"])
    @layer = authorize map.layers.new
  end

  def update
    if @layer.update(layer_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to layer_path(@layer) }
      end
    else
      render :show, status: :unprocessable_entity
    end
  end

  def create
    map = current_user.maps.find(layer_params["map_id"])

    layer = authorize map.layers.new(layer_params)
    if layer.save
      redirect_to layer_path(layer)
    else
      # This line overrides the default rendering behavior, which
      # would have been to render the "create" view.
      render "new", status: :unprocessable_entity
    end
  end

  def destroy
    @layer.destroy
    redirect_to maps_url, notice: t("helpers.message.layer.destroyed"), status: :see_other
  end

  def schema
    properties = @layer.fields.all.map { |f| field_schema(f) }.to_h

    render json: {
      type: :object,
      properties: properties
    }.to_json
  end

  def geojson
    send_data RGeo::GeoJSON.encode(@layer.geo_feature_collection).to_json, filename: "#{@layer.name}.geojson", type: "application/geo+json"
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
        sign_in User.new(access_groups: [access_group])
      else
        render plain: t("api.bad_key"), status: :unauthorized
      end
    end
  end
end
