class LayerPolicy < ApplicationPolicy
  def new? = update?

  def create? = update?

  def show? = access_group.present?

  def schema? = show?

  def geojson? = show?

  def edit? = update? || access_group&.contributor?

  def update? = access_group&.owner? || access_group&.editor?

  def destroy? = access_group&.owner?

  private

  def access_group
    user&.access_groups&.find_by(map: record.map)
  end
end
