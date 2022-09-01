class TerritoryCategoryPolicy < ApplicationPolicy
  def show? = true

  class Scope < Scope
    def resolve = TerritoryCategory.all
  end
end
