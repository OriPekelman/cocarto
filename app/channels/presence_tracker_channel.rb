class PresenceTrackerChannel < ApplicationCable::Channel
  include Pundit::Authorization

  before_subscribe :find_layer

  def subscribed
    stream_for @layer
  end

  def mouse_moved(data)
    broadcast_to @layer, data
  end

  private

  def find_layer
    @layer = authorize Layer.find(params[:layer]), :show?
  end
end
