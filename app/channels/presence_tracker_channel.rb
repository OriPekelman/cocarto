class PresenceTrackerChannel < ApplicationCable::Channel
  include Pundit::Authorization

  before_subscribe :set_cid, :find_layer

  def subscribed
    stream_for @layer
  end

  def mouse_moved(data)
    data = data.slice("lngLat")
      .merge(
        name: current_user.display_name,
        cid: @cid
      )
    broadcast_to @layer, data
  end

  private

  def set_cid
    # Client id: Identifies different tabs for the same user
    @cid = params[:cid]
  end

  def find_layer
    @layer = authorize Layer.find(params[:layer]), :show?
  end
end
