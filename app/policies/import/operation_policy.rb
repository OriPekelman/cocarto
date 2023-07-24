class Import::OperationPolicy < ApplicationPolicy
  def new? = create?

  def create? = map_access&.is_at_least(:contributor)

  def show? = create?

  private

  def map_access
    @map_access ||= user.access_for_map(record.configuration.map)
  end
end
