class RowsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_row, only: %i[destroy update edit]
  before_action :set_layer, only: %i[create new update destroy]

  def new
    @row = authorize @layer.rows.new
    @values = {}
  end

  def edit
    # Only used for files fields
    @field = Field.find(params[:field_id])
    raise NotImplementedError unless @field.type_files?
  end

  def create
    from_rows_new = params[:from_rows_new]
    @row = authorize Row.create(layer: @layer, **row_params, author: current_user)
    if @row.valid?
      if from_rows_new
        flash[:notice] = t("helpers.message.row.added")
        redirect_to new_layer_row_path
      else
        respond_to do |format|
          format.turbo_stream
          if from_rows_new
            redirect_to new_layer_row_path
          else
            format.html { redirect_to @row.map }
          end
        end
      end
    else
      render_error
    end
  end

  def update
    if @row.update(row_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @row.map, notice: t("helpers.message.row.updated") }
      end
    else
      render_error [turbo_stream.replace(@row, html: @row.render)]
    end
  end

  def destroy
    @row.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @row.layer, notice: t("helpers.message.row.destroyed") }
    end
  end

  def render_error(extra_content = [])
    flash.now[:error] = @row.errors.first.full_message
    respond_to do |format|
      format.turbo_stream { render turbo_stream: [turbo_stream.replace("flash", partial: "layouts/flash")] + extra_content }
      format.html { redirect_to @row.map }
    end
  end

  private

  def set_row
    @row = authorize Row.find(params[:id]).reload_with_fields_values(layer: [:fields, :map])
  end

  def set_layer
    @layer = Layer.includes(:fields, :map).find(params[:layer_id])
  end

  def row_params
    simple_fields = @layer.fields.reject(&:multiple?).map(&:id)
    multiple_fields = @layer.fields.filter(&:multiple?).map { |field| {field.id => []} }
    params.require(:row).permit(:geojson, :territory_id, :field_id, fields_values: simple_fields + multiple_fields)
  end
end
