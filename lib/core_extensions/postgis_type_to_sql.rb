# Temporary fix until https://github.com/rgeo/activerecord-postgis-adapter/pull/377
module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module SchemaStatements
        def type_to_sql(type, limit: nil, precision: nil, scale: nil, array: nil, **)
          if ["geometry", "geography"].include?(type.to_s) && limit.is_a?(Hash)
            limit = ColumnDefinitionUtils.limit_from_options(type, limit)
            "#{type}(#{limit})"
          else
            super
          end
        end
      end
    end
  end
end
