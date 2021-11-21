class PointsController < ApplicationController
  before_action :set_point, only: %i[destroy update]
  before_action :set_layer, only: %i[create update]

  def create
    point = params.require(:point).permit(:longitude, :latitude, :layer_id)

    attributes = {
      layer_id: @layer.id,
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

  def update
    @point.update(fields: fields)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @layer, notice: "Point was successfully updated." }
    end
  end

  private

  def set_point
    @point = Point.find(params[:id])
  end

  def set_layer
    layer_id = params[:point][:layer_id]
    @layer = Layer.find(layer_id)
  end

  def fields
    field_keys = @layer.fields.map { |field| field.id }
    params.require(:point).permit(field_keys)
  end
end
