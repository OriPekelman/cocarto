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
    @field = Field.new(field_params)
    if @field.save
      redirect_to @field.layer
    else
      # This line overrides the default rendering behavior, which
      # would have been to render the "create" view.
      render "new"
    end
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
