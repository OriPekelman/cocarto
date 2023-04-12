class ImportController < ApplicationController
  before_action :set_layer

  def show
  end

  def create
    path = params[:file].path
    csv = File.read(path)
    ImportExport.import(@layer, :csv, csv, author: current_user, stream: true)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @layer, notice: t(".import_successful") }
    end
  rescue => e
    @layer.errors.add(:base, e.message)
    render "show", status: :unprocessable_entity, alert: t(".import_failed")
  end

  private

  def set_layer
    @layer = authorize Layer.find(params[:layer_id])
  end
end
