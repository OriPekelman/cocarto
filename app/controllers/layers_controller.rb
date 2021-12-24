require "securerandom"

class LayersController < ApplicationController
  before_action :set_layer, only: %i[show edit update destroy]

  def index
    @layers = Layer.all
  end

  def show
  end

  def new
    @layer = Layer.new
  end

  def edit
    # Every time we open a new tab, we create this session id
    # It allows to keep track what
    @session_id = SecureRandom.alphanumeric
  end

  def update
    if @layer.update(layer_params)
      redirect_to @layer, notice: "Layer was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    @layer = Layer.new(layer_params)
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
    redirect_to layers_url, notice: "Layer was successfully destroyed."
  end

  private

  def set_layer
    @layer = Layer.find(params[:id])
  end

  def layer_params
    params.require(:layer).permit(:name, :geometry_type)
  end
end
