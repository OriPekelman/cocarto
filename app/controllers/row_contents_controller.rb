class RowContentsController < ApplicationController
  before_action :set_row_content, only: %i[destroy update]

  def destroy
    @row_content.geometry.destroy
    @row_content.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @row_content.layer, notice: "Geometry was successfully destroyed." }
    end
  end

  def update
    @row_content.update(values: fields)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @row_content.layer, notice: "Geometry properties were successfully updated." }
    end
  end

  private

  def set_row_content
    @row_content = RowContent.find(params[:id])
  end

  def fields
    field_keys = @row_content.layer.fields.map { |field| field.id }
    params.require(:row_content).permit(field_keys)
  end
end
