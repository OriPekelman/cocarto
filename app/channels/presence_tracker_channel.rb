class PresenceTrackerChannel < ApplicationCable::Channel
  include Pundit::Authorization

  before_subscribe :set_cid, :find_map

  def subscribed
    stream_for @map
  end

  def mouse_moved(data)
    data = data.slice("lngLat")
      .merge(
        name: current_user.display_name,
        cid: @cid
      )
    broadcast_to @map, data
  end

  private

  def set_cid
    # Client id: Identifies different tabs for the same user
    @cid = params[:cid]
  end

  def find_map
    @map = authorize Map.find(params[:map]), :show?
  end
end
