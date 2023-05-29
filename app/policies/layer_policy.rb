class LayerPolicy < ApplicationPolicy
  def new? = create?

  def create? = map_access&.is_at_least(:editor)

  def show? = map_access.present?

  def update? = create?

  def destroy? = create?

  def mvt? = show?

  private

  def map_access
    @map_access ||= user.access_for_map(record.map)
  end
end
