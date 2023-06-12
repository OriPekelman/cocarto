module RoleType
  # Map Access Roles, used in UserRole and MapToken
  extend ActiveSupport::Concern

  # Roles are comparable in order, first is best
  ROLES = %w[owner editor contributor viewer]

  module ClassMethods
    def role_types_enum(roles) # defines the enum on the record class, with only the passed values.
      enum :role_type, roles.index_with { _1.to_s }
    end
  end

  # Strength comparison
  def is_stronger_than(other_map_access)
    ROLES.index(role_type) < ROLES.index(other_map_access.role_type)
  end

  def is_at_least(other_role_type) # Note: the receiver is a record, the argument is a role name.
    ROLES.index(role_type) <= ROLES.index(other_role_type.to_s)
  end
end
