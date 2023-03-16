# Dynamic Fields Associations
#
# Allow preloading the territories for rows with territory_type field values.
# We dynamically generate associations between Row instances and Territories.
# It is a belongs_to relation using `row.values[field.id]` as the foreign key.
#
# This is a bit of a hack and workarounds deep inside ActiveRecords preloading mechanisms, Arel, and SQL generation.
# As of now, this only supports relations to Territory, but it should work fine in the general Row->Row situation.
#
# The dynamic associations can be used for `.preloading`/`.eager_loading`, but not for `.joins` or `.left_outer_joins`.
module FieldValuesAssociations
  module AssociationName # included by Field
    def association_name
      "#{Internal::ASSOCIATION_PREFIX}#{id}"
    end
  end

  module RowAssociations # included by Row
    extend ActiveSupport::Concern
    # Override some ActiveRecord methods in Row

    # Builds a BelongsToAssociation between the Row instance (self) and a Territory instance.
    # This is how ActiveRecord describes an association between two model instances.
    # This is used:
    # - for preloading in ActiveRecord::Associations::Preloader::Branch
    # - for eager loading: ActiveRecord::Associations::JoinDependency
    def association(name)
      if name.starts_with? Internal::ASSOCIATION_PREFIX
        @values_associations ||= {}
        @values_associations[name.to_sym] ||= begin
          reflection = Internal.value_association_reflection(name)
          reflection.association_class.new(self, reflection)
        end
      else
        super
      end
    end

    # Access the “foreign key”, i.e. the territory field value.
    # This is used for preloading in ActiveRecord::Associations::Preloader::Association
    # to get the list of ids of the Territories to preload.
    def read_attribute(attr_name, &block)
      if attr_name.starts_with? Internal::FOREIGN_KEY_PREFIX
        field_id = attr_name.delete_prefix(Internal::FOREIGN_KEY_PREFIX).delete("'")
        values[field_id]
      else
        super
      end
    end

    # Also overload _read_attribute:
    # - it’s the method used by and BelonsToAssociation#stale_state. Otherwise, #stale_state is always nil, which makes #stale_target? always return false.
    # - it allows loading the association of a single object, without preloading.
    # E.g., given a row r and a territory field f, this returns the territory:
    # `row.association(field.association_name).reader`
    # Note: the reader method defined by belongs_to is implemented as `association(:#{name}).reader`.
    def _read_attribute(attr_name, &block)
      if attr_name.starts_with? Internal::FOREIGN_KEY_PREFIX
        field_id = attr_name.delete_prefix(Internal::FOREIGN_KEY_PREFIX).delete("'")
        values[field_id]
      else
        super
      end
    end

    class_methods do
      # Return the type of the “foreign key”
      # This is used for preloading in ActiveRecord::Associations::Preloader::Association.
      def type_for_attribute(key_name)
        if key_name.starts_with? Internal::FOREIGN_KEY_PREFIX
          ActiveModel::Type::String.new # We could return anything that responds to :type
        else
          super
        end
      end

      # Return the reflection for an association name.
      # This is used:
      # - for preloading: in ActiveRecord::Associations::Preloader::Branch
      # - for eager loading: ActiveRecord::Associations::JoinDependency
      def _reflect_on_association(association_name)
        if association_name.starts_with? Internal::ASSOCIATION_PREFIX
          Internal.value_association_reflection(association_name)
        else
          super
        end
      end
    end
  end

  module Internal
    ASSOCIATION_PREFIX = "cocarto_field_".freeze
    FOREIGN_KEY_PREFIX = "values->>".freeze

    # Return the Reflection (the abstract description) of the Row.belongs_to relation to a territory via the field value
    # Note: we create a new Reflection everytime, which is unfortunate but
    # we can’t cache the Reflections on the Row class, as ActiveRecord does for the regular relations.
    def value_association_reflection(association_name)
      raise ArgumentError unless association_name.starts_with? ASSOCIATION_PREFIX

      field_id = association_name.to_s.delete_prefix(ASSOCIATION_PREFIX)

      options = {class_name: "Territory", optional: true, primary_key: :id, foreign_key: "#{FOREIGN_KEY_PREFIX}'#{field_id}'"}
      ValueAssociationReflection.new(association_name, nil, options, Row)
    end
    module_function :value_association_reflection

    # Override BelongsToReflection
    # BelongsToReflection does not support Arel::Nodes::SqlLiteral for foreign_key; it converts it to a String.
    # When building the SQL later, it ends up improperly quoted as if “values->>1234-abcd” was a column name.
    # Additionally, we need to cast the json value to uuid.
    # This is used:
    # - for eager loading: in ActiveRecord::Associations::JoinDependency
    class ValueAssociationReflection < ActiveRecord::Reflection::BelongsToReflection
      def join_scope(table, foreign_table, foreign_klass)
        # call super and override the where condition
        condition = table[join_primary_key].eq(Arel::Nodes::SqlLiteral.new("(#{foreign_table.name}.#{join_foreign_key})::uuid"))
        super.rewhere(condition)
      end
    end
  end
end
