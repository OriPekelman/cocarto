class PresenceTrackerChannel < ApplicationCable::Channel
  include Pundit::Authorization
  include ActionView::RecordIdentifier # for `dom_id`

  before_subscribe :find_layer

  def subscribed
    stream_from dom_id(@layer)
  end

  def mouse_moved(data)
    ActionCable.server.broadcast(dom_id(@layer), data)
  end

  private

  def find_layer
    @layer = authorize Layer.find(params[:layer]), :show?
  end
end
