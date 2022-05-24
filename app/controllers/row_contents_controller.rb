class RowContentsController < ApplicationController
  before_action :set_layer, only: %i[create new]
  before_action :set_row_content, only: %i[edit destroy update]

  def new
    @row_content = @layer.row_contents.new
    # The form is filled by someone that shouldn’t be redirected to the main page
    @anonymous = true
    @values = {}
  end

  def edit
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
      format.html { redirect_to @row_content.layer, notice: t("error_message_row_contents_destroy") }
    end
  end

  def update
    @row_content.update(values: fields(@row_content.layer))
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @row_content.layer, notice: t("error_message_row_contents_update") }
    end
  end

  private

  def set_row_content
    @row_content = RowContent.includes(layer: [:fields]).find(params[:id])
  end

  def fields(layer)
    layer.fields.map do |field|
      # Some inputs match a territory
      # If the value is empty, it means that we didn’t select a territory, so we don’t want to store it
      if field.field_type == "territory" && params[:row_content][field.id].empty?
        nil
      else
        [field.id, params[:row_content][field.id]]
      end
    end.reject(&:nil?).to_h
  end

  def set_layer
    layer_id = params[:layer_id] || params[:row_content][:layer_id]
    @layer = Layer.includes(:fields).find(layer_id)
  end
end
