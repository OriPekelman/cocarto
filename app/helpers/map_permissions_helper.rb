module MapPermissionsHelper
  def options_for_role_type_select(record)
    options = record.class.role_types.map do |role_type|
      [UserRole.human_attribute_name("role_types.#{role_type[0]}"), role_type[1]]
    end
    options_for_select(options, record.role_type)
  end
end
