class PresenceTrackerChannel < ApplicationCable::Channel
  def subscribed
    stream_from "layer_#{params[:layer]}"
  end

  def mouse_moved(data)
    ActionCable.server.broadcast("layer_#{params[:layer]}", data)
  end
end
