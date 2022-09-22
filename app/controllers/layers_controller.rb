require "securerandom"

class LayersController < ApplicationController
  before_action :set_layer, only: %i[show update destroy schema geojson]
  before_action :set_user_name
  before_action :authenticate_user!

  def show
    # Every time we open a new tab, we create this session id
    # It allows to keep track of who is currently on the page
    # It differs from current_user as a user can be connected many times on the same page
    @session_id = SecureRandom.alphanumeric
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
    @layer = authorize Layer.includes(:fields, :map, rows: :territory).find(params[:id])
  end

  def set_user_name
    @user_name = if user_signed_in?
      current_user.email.split("@")[0]
    else
      "anonymous"
    end
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
end
