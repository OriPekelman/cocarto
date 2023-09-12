require "securerandom"

class LayersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_layer, only: %i[show edit update destroy mvt]

  def show
    respond_to do |format|
      format.html { redirect_to map_path(@layer.map, params: {open: @layer}) }
      format.any(*ImportExport::EXPORTERS.keys) do
        allow_origin_everywhere
        data = ImportExport.export(@layer, request.format.to_sym)
        send_data data, filename: "#{@layer.name}.#{request.format.to_sym}", type: Mime[request.format]
      end
    end
  end

  def new
    map = current_user.maps.find(params["map_id"])
    @layer = authorize map.layers.new
    render :form
  end

  def edit
    render :form
  end

  def create
    map = current_user.maps.includes(:layers).find(layer_params["map_id"])

    layer = authorize map.layers.new(layer_params)
    if layer.save
      respond_to do |format|
        format.turbo_stream { render turbo_stream: [] }
        format.html { redirect_to layer }
      end
    else
      # This line overrides the default rendering behavior, which
      # would have been to render the "create" view.
      render :form, status: :unprocessable_entity
    end
  end

  def update
    if @layer.update(layer_params)
      @layer.broadcast_i18n_replace_to @layer.map
      respond_to do |format|
        format.turbo_stream { render turbo_stream: [] }
        format.html { redirect_to @layer }
      end
    else
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    @layer.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: [] }
      format.html { redirect_to @layer.map, notice: t("helpers.message.layer.destroyed"), status: :see_other }
    end
  end

  def mvt
    # MVT is a vector tile format used to render features on a map
    # A tile in the xyz is defined by its zoom level (z) and position on the map
    # This functions returs the MVT tile of the current layer
    x, y, z = params[:x], params[:y], params[:z]
    tile = Rails.cache.fetch([@layer, "mvt", x, y, z]) { @layer.as_mvt(x, y, z) }
    send_data tile
  end

  private

  def set_layer
    @layer = authorize Layer.includes(:map, :import_mappings, rows: :territory, fields: :territory_categories).find(params[:id])
  end

  def layer_params
    params.require(:layer).permit(:name, :geometry_type, :map_id, :color, territory_category_ids: [])
  end

  def allow_origin_everywhere
    headers["Access-Control-Allow-Origin"] = "*"
    headers["Access-Control-Allow-Methods"] = "GET OPTIONS"
    headers["Access-Control-Allow-Headers"] = "*"
  end
end
