class FieldsController < ApplicationController
  before_action :set_field, only: %i[show edit update destroy]

  def new
    @field = Field.new
  end

  def edit
  end

  def update
    if @field.update(field_params)
      redirect_to @field, notice: t("error_message_field_update")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    @layer = Layer.find(field_params[:layer_id])
    @field = @layer.fields.create(field_params)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @field.layer }
    end
  end

  def destroy
    @field.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @field.layer, notice: t("error_message_field_destroy") }
    end
  end

  private

  def set_field
    @field = Field.find(params[:id])
  end

  def field_params
    params.require(:field).permit(:label, :layer_id, :field_type)
  end
end
