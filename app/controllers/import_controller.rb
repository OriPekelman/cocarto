class ImportController < ApplicationController
  before_action :set_layer

  def show
  end

  def new
  end

  def create
    if import_params[:file].present?
      path = import_params[:file].path
      csv = File.open(path)
      @result = ImportExport.import(@layer, :csv, csv, key_field: import_params[:key_field], author: current_user, stream: true, ignore_empty_geometry_rows: true)
    elsif import_params[:url].present?
      @result = ImportExport.import(@layer, :wfs, import_params[:url], key_field: import_params[:key_field], input_layer_name: import_params[:input_layer_name], author: current_user, stream: true, ignore_empty_geometry_rows: true)
    end
    if @result.success?
      render "show"
    else
      render "new", status: :unprocessable_entity
    end
  end

  private

  def import_params
    # TODO: `slice` is needed because we don't have proper ImportOperation resources yet.
    keys = [:key_field, :file, :url, :input_layer_name]
    params.slice(*keys).permit(*keys)
  end

  def set_layer
    @layer = Layer.find(params[:layer_id])
    authorize @layer.rows.new, :create?
  end
end
