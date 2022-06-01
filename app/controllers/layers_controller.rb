require "securerandom"

class LayersController < ApplicationController
  before_action :set_layer, only: %i[show edit update destroy schema]
  before_action :authenticate_user!

  def index
    @layers = current_user.layers.all
  end

  def show
  end

  def new
    @layer = current_user.layers.new
  end

  def edit
    # Every time we open a new tab, we create this session id
    # It allows to keep track what
    @session_id = SecureRandom.alphanumeric
  end

  def update
    if @layer.update(layer_params)
      redirect_to @layer, notice: t("error_message_layer_update")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    @layer = current_user.layers.new(layer_params)
    if @layer.save
      redirect_to @layer
    else
      # This line overrides the default rendering behavior, which
      # would have been to render the "create" view.
      render "new"
    end
  end

  def destroy
    @layer.destroy
    redirect_to layers_url, notice: t("error_message_layer_destroy")
  end

  def schema
    properties = @layer.fields.all.map { |f| field_schema(f) }.to_h

    render json: {
      type: :object,
      properties: properties
    }.to_json
  end

  private

  def set_layer
    @layer = current_user.layers.includes(:fields, :row_contents).find(params[:id])
  end

  def layer_params
    params.require(:layer).permit(:name, :geometry_type)
  end

  def field_schema(field)
    mapping = {
      "text" => :string,
      "float" => :number,
      "integer" => :integer
    }

    [field.id, type: mapping[field.field_type], title: field.label]
  end
end
