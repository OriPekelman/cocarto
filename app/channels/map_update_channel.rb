class MapUpdateChannel < ApplicationCable::Channel
  include Pundit::Authorization

  before_subscribe :find_map

  def subscribed
    stream_for @map
  end

  private

  def find_map
    @map = authorize Map.find(params[:map]), :show?
  end
end
