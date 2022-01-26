class PointsController < ApplicationController
  before_action :set_layer, only: %i[create new update]

  def new
    @point = @layer.points.new
    # The form is filled by someone that shouldn’t be redirected to the main page
    @anonymous = true
    @values = {}
  end

  def edit
    @point = Point.find(params[:id])
    @layer = @point.layer
    @values = @point.row_content.values
  end

  def update
    @point = Point.find(params[:id])
    @point.row_content.update({values: fields})
    redirect_to action: :edit, id: @point
  end

  def create
    point = params.require(:point).permit(:longitude, :latitude, :layer_id, :anonymous)

    @point = @layer.points.create({
      layer: @layer,
      geog: RGEO_FACTORY.point(point[:longitude], point[:latitude]),
      row_content: RowContent.create({
        values: fields,
        layer: @layer
      })
    })

    if point[:anonymous] == "true"
      redirect_to action: :edit, id: @point
    else
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @point.layer }
      end
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
