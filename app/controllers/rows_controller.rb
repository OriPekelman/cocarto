class RowsController < ApplicationController
  before_action :set_row, only: %i[edit destroy update]
  before_action :set_layer, only: %i[create new update]

  def new
    @row = @layer.rows.new
    # The form is filled by someone that shouldn’t be redirected to the main page
    @anonymous = true
    @values = {}
  end

  def edit
    @layer = @row.layer
    @values = @row.values
  end

  def create
    anonymous = params.require(:row)[:annonymous] == "true"

    @row = Row.create(layer: @layer, **row_params)

    if anonymous
      redirect_to action: :edit, id: @row
    else
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to layer_path(@row.layer) }
      end
    end
  end

  def destroy
    @row.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @row.layer, notice: t("error_message_row_destroy") }
    end
  end

  def update
    @row.update(row_params)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to layer_path(@row.layer), notice: t("error_message_row_update") }
    end
  end

  private

  def set_row
    @row = Row.includes(layer: :fields).find(params[:id])
  end

  def set_layer
    @layer = Layer.includes(:fields, :map).find(params[:layer_id])
  end

  def row_params
    @row_params ||= params.require(:row).permit(:geojson, fields_values: @layer.fields.ids)
  end
end
