class RowsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_row, only: %i[show edit update destroy]
  before_action :set_layer, only: %i[create new]

  def show
    respond_to do |format|
      format.geojson do
        geojson = RGeo::GeoJSON.encode(ImportExport::GeojsonExporter.new(@row.layer, with_ids: true).exported_row(@row))
        render json: geojson
      end
    end
  end

  def new
    @row = authorize @layer.rows.new
    @values = {}
  end

  def edit
    if params[:focus_field_id]
      @focus_field = Field.find(params[:focus_field_id])
    end
    @role_type = current_user.access_for_map(@row.map).role_type
  end

  def create
    from_rows_new = params[:from_rows_new]
    @row = authorize Row.create(layer: @layer, **row_params(@layer.fields), author: current_user)
    if @row.valid?
      if from_rows_new
        redirect_to new_layer_row_path, notice: t("helpers.message.row.added")
      else
        respond_to do |format|
          format.turbo_stream { render turbo_stream: [] }
          format.html { redirect_to @row.map, notice: t("helpers.message.row.added") }
        end
      end
    else
      render_error
    end
  end

  def update
    if @row.update(row_params(@row.layer.fields))
      respond_to do |format|
        format.turbo_stream { render turbo_stream: [] }
        format.html { redirect_to @row.map, notice: t("helpers.message.row.updated") }
      end
    else
      render_error [turbo_stream.replace(@row, html: @row.render)]
    end
  end

  def destroy
    @row.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: [] }
      format.html { redirect_to @row.layer, notice: t("helpers.message.row.destroyed"), status: :see_other }
    end
  end

  def render_error(extra_content = [])
    flash.now[:error] = @row.errors.first.full_message
    respond_to do |format|
      format.turbo_stream { render turbo_stream: extra_content }
      format.html { redirect_to @row.map }
    end
  end

  private

  def set_row
    @row = authorize Row.find(params[:id]).reload_with_fields_values(:map, layer: [:fields, :map])
  end

  def set_layer
    @layer = Layer.includes(:fields, :map).find(params[:layer_id])
  end

  def row_params(fields)
    simple_fields = fields.reject(&:multiple?).map(&:id)
    multiple_fields = fields.filter(&:multiple?).map { |field| {field.id => []} }
    params.require(:row).permit(:geojson, :territory_id, :field_id, fields_values: simple_fields + multiple_fields)
  end
end
