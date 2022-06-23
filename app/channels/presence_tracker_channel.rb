class PresenceTrackerChannel < ApplicationCable::Channel
  def subscribed
    stream_from "layer_#{params[:layerId]}"
  end

  def mouse_moved(data)
    ActionCable.server.broadcast("layer_#{params[:layerId]}", data)
  end
end
