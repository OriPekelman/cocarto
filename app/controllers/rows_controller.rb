class RowsController < ApplicationController
  before_action :set_row, only: %i[edit destroy update]
  before_action :set_layer, only: %i[create new update]

  def new
    @row = authorize @layer.rows.new
    @values = {}
  end

  def create
    @row = authorize Row.create(layer: @layer, **row_params, author: current_user)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to layer_path(@row.layer) }
    end
  end

  def destroy
    @row.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @row.layer, notice: t("helpers.message.row.destroyed") }
    end
  end

  def update
    @row.update(row_params)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to layer_path(@row.layer), notice: t("helpers.message.row.updated") }
    end
  end

  private

  def set_row
    @row = authorize Row.includes(layer: :fields).find(params[:id])
  end

  def set_layer
    @layer = Layer.includes(:fields, :map).find(params[:layer_id])
  end

  def row_params
    @row_params = params.require(:row).permit(:geojson, :territory_id, fields_values: @layer.fields.ids)
  end
end
