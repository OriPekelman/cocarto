class Import::OperationsController < ApplicationController
  before_action :set_map, only: [:new, :create]
  before_action :set_operation, only: [:show]

  def show
  end

  def new
    mapping = @layer.present? ? Import::Mapping.new(layer: @layer) : nil
    configuration = Import::Configuration.new(map: @map, mappings: Array(mapping))
    @operation = authorize Import::Operation.new(configuration: configuration)
  end

  def create
    operation_params = source_analysis(import_params)
    @operation = authorize Import::Operation.new(operation_params)

    if @operation.save
      redirect_to @operation
      @operation.import(current_user)
    else
      render "new", status: :unprocessable_entity
    end
  end

  private

  def source_analysis(params)
    # TODO: Proper Analysis system, see #305
    mapping = {
      "text/csv" => :csv,
      "application/json" => :geojson
    }

    if params[:local_source_file].present?
      params[:configuration_attributes][:source_type] = mapping[import_params[:local_source_file].content_type]
    end

    if params[:remote_source_url].present?
      params[:configuration_attributes][:source_type] = :wfs
    end

    params
  end

  def import_params
    params.require(:import_operation)
      .permit(:local_source_file, :remote_source_url,
        configuration_attributes: [:map_id,
          mappings_attributes: [:layer_id, :reimport_field_id, :source_layer_name, :source_csv_column_separator, :source_text_encoding,
            :geometry_encoding_format, geometry_columns: [], fields_columns: []]])
  end

  def set_map
    @map = Map.find(params[:map_id])
    @layer = Layer.find_by(id: params[:layer_id])
  end

  def set_operation
    @operation = authorize Import::Operation.find(params[:id])
  end
end
