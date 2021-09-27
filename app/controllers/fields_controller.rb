class FieldsController < ApplicationController
  before_action :set_field, only: %i[show edit update destroy]

  def new
    @field = Field.new
  end

  def edit
  end

  def update
    if @field.update(field_params)
      redirect_to @field, notice: "Field was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    @layer = Layer.find(params[:layer_id])
    @field = @layer.fields.create(field_params)
    redirect_to @layer
  end

  def destroy
    @field.destroy
    redirect_to fields_url, notice: "Field was successfully destroyed."
  end

  private

  def set_field
    @field = Field.find(params[:id])
  end

  def field_params
    params.require(:field).permit(:label, :layer_id, :field_type)
  end
end
