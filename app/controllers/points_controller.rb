class PointsController < ApplicationController
  before_action :set_point, only: %i[destroy]

  def create
    layer_id = params[:point][:layer_id]
    @layer = Layer.find(layer_id)
    field_keys = @layer.fields.map { |field| field.label }
    fields = params.require(:point).permit(field_keys)

    attributes = {
      layer_id: layer_id,
      geog: RGEO_FACTORY.point(point[:longitude], point[:latitude]),
      fields: fields
    }

    @point = @layer.points.create(attributes)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @point.layer }
    end
  end

  def destroy
    @point.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @point.layer, notice: "Point was successfully destroyed." }
    end
  end

  private

  def set_point
    @point = Point.find(params[:id])
  end
end
