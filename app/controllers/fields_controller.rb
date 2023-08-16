class FieldsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_field, only: %i[update destroy]

  def create
    @field = authorize Field.new(field_params)

    if @field.save
      flash.now[:notice] = t("helpers.message.field.created", name: @field.label)
    else
      flash.now[:alert] = @field.errors.first.full_message
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(helpers.dom_id(@field.layer, :new_field), Field.new(layer: @field.layer)) # Clear the “new_field” form
        ]
      end
      format.html { redirect_to @field.layer }
    end
  end

  def update
    if @field.update(field_params)
      flash.now[:notice] = t("helpers.message.field.updated")
    else
      flash.now[:alert] = @field.errors.first.full_message
    end

    respond_to do |format|
      format.turbo_stream { render turbo_stream: [] }
      format.html { redirect_to @field.layer }
    end
  end

  def destroy
    if @field.destroy
      flash.now[:notice] = t("helpers.message.field.destroyed")
    else
      flash.now[:alert] = @field.errors.first.full_message
    end

    respond_to do |format|
      format.turbo_stream { render turbo_stream: [] }
      format.html { redirect_to @field.layer, status: :see_other }
    end
  end

  private

  def set_field
    @field = authorize Field.includes(:territory_categories, layer: [:map, :rows, :fields]).find(params[:id])
  end

  def field_params
    params.require(:field).permit(:label, :layer_id, :locked, :field_type, :text_is_long, enum_values: [], territory_category_ids: [])
  end
end
