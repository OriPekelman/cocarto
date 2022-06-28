class MapsController < ApplicationController
  def index
    @maps = current_user.maps.all
  end
end
