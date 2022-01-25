class PointsController < ApplicationController
  before_action :set_layer, only: %i[create new]

  def new
    @point = @layer.points.new
  end

  def create
    point = params.require(:point).permit(:longitude, :latitude, :layer_id)

    @point = @layer.points.create({
      layer: @layer,
      geog: RGEO_FACTORY.point(point[:longitude], point[:latitude]),
      row_content: RowContent.create({
        values: fields,
        layer: @layer
      })
    })

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @point.layer }
    end
  end

  private

  def fields
    field_keys = @layer.fields.map { |field| field.id }
    params.require(:point).permit(field_keys)
  end

  def set_layer
    layer_id = params[:layer_id] || params[:point][:layer_id]
    @layer = Layer.find(layer_id)
  end
end
