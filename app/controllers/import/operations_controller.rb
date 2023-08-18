class Import::OperationsController < ApplicationController
  before_action :set_map, only: [:new, :create]
  before_action :set_operation, only: [:show, :update, :destroy]

  def show
    @operation.analysis
  end

  def new
    mapping = @layer.present? ? Import::Mapping.new(layer: @layer) : nil
    configuration = Import::Configuration.new(map: @map, mappings: Array(mapping))
    @operation = authorize Import::Operation.new(configuration: configuration)
  end

  def create
    @operation = authorize Import::Operation.new(import_params)

    if @operation.save
      @operation.configure_from_source
      redirect_to @operation
    else
      render "new", status: :unprocessable_entity
    end
  end

  def update
    @operation.update!(import_params)
    @operation.configure_from_source

    if params[:commit].present? # The user actually clicked the import button
      @operation.import(current_user)
    end
    redirect_to @operation
  end

  def destroy
    @operation.destroy
    redirect_to new_map_import_operation_path(@operation.configuration.map, layer_id: @operation.configuration.mappings.first.layer)
  end

  private

  def import_params
    params.require(:import_operation)
      .permit(:local_source_file, :remote_source_url,
        configuration_attributes: [:id, :map_id, :source_type, :name, :source_csv_column_separator, :source_text_encoding,
          mappings_attributes: [:id, :_destroy, :layer_id, :reimport_field_id, :source_layer_name, :source_csv_column_separator, :source_text_encoding,
            :geometry_encoding_format, geometry_columns: [], fields_columns: {}]])
  end

  def set_map
    @map = Map.find(params[:map_id])
    @layer = Layer.find_by(id: params[:layer_id])
  end

  def set_operation
    @operation = authorize Import::Operation.with_attached_local_source_file.includes(configuration: [map: :layers, mappings: [layer: :fields]]).find(params[:id])
  end
end
