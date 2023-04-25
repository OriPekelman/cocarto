class ImportController < ApplicationController
  before_action :set_layer

  def show
  end

  def create
    path = import_params[:file].path
    csv = File.open(path)
    ImportExport.import(@layer, :csv, csv, key_field: import_params[:key_field], author: current_user, stream: true)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @layer, notice: t(".import_successful") }
    end
  rescue => e
    @layer.errors.add(:base, e.message)
    render "show", status: :unprocessable_entity, alert: t(".import_failed")
  end

  private

  def import_params
    params.slice(:key_field, :file)
      .permit(:key_field, :file)
  end

  def set_layer
    @layer = Layer.find(params[:layer_id])
    authorize @layer.rows.new, :create?
  end
end
