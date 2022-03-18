class RowContentsController < ApplicationController
  before_action :set_layer, only: %i[create new]
  before_action :set_row_content, only: %i[destroy update]

  def new
    @row_content = @layer.row_contents.new
    # The form is filled by someone that shouldn’t be redirected to the main page
    @anonymous = true
    @values = {}
  end

  def edit
    @row_content = RowContents.find(params[:id])
    @layer = @row_content.layer
    @values = @row_content.values
  end

  def create
    point = params.require(:row_content).permit(:longitude, :latitude, :layer_id, :anonymous)

    @row_content = @layer.row_contents.create({
      layer: @layer,
      point: RGEO_FACTORY.point(point[:longitude], point[:latitude]),
      values: fields(@layer)
    })

    if point[:anonymous] == "true"
      redirect_to action: :edit, id: @row_content
    else
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @row_content.layer }
      end
    end
  end

  def destroy
    @row_content.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @row_content.layer, notice: "Geometry was successfully destroyed." }
    end
  end

  def update
    @row_content.update(values: fields(@row_content.layer))
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @row_content.layer, notice: "Geometry properties were successfully updated." }
    end
  end

  private

  def set_row_content
    @row_content = RowContent.find(params[:id])
    puts @row_content
  end

  def fields(layer)
    field_keys = layer.fields.map { |field| field.id }
    params.require(:row_content).permit(field_keys)
  end

  def set_layer
    layer_id = params[:layer_id] || params[:row_content][:layer_id]
    @layer = Layer.find(layer_id)
  end
end
