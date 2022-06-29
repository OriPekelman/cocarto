class FieldsController < ApplicationController
  before_action :set_field, only: %i[edit update destroy]

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
    layer = Layer.includes(:rows).find(field_params[:layer_id])
    @field = layer.fields.new(field_params)

    if @field.save
      flash.now[:notice] = t("new field created", name: @field.label)
    else
      flash.now[:alert] = @field.errors.first.full_message
    end

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
    @field = Field.includes(:layer).find(params[:id])
  end

  def field_params
    params.require(:field).permit(:label, :layer_id, :field_type)
  end
end
