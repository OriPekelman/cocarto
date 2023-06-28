class ImportController < ApplicationController
  before_action :set_layer

  def show
  end

  def new
  end

  def create
    path = import_params[:file].path
    csv = File.open(path)
    @result = ImportExport.import(@layer, :csv, csv, key_field: import_params[:key_field], author: current_user, stream: true)
    if @result.success?
      render "show"
    else
      render "new", status: :unprocessable_entity
    end
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
