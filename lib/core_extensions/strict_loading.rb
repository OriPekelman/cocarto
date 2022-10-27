module CoreExtensions
  module StrictLoading
    # The strict_loading mode :n_plus_one_only works in an unexpected way:
    # Its only effect is when a has_many collection is loaded: in that case,
    # the new fetched object are set with strict_loading_mode :all.
    #
    # This is the expected way to use strict loading:

    # 1. When fetching a collection:
    #    maps = Map.strict_loading!.all
    #    map = maps.first <- map.strict_loading_mode is :all
    #    layer = map.layers.first <- Raises ActiveRecord::StrictLoadingViolationError

    # 2. When fetching a single object:
    #    map = Map.find(...)
    #    map.strict_loading!(true, mode: :n_plus_one_only)
    #    layer = map.layers.first <- Now layer.strict_loading_mode is :all
    #    layer.rows.inspect <- Raises ActiveRecord::StrictLoadingViolationError
    #
    # We want to do it automatically.
    #
    # Note: the Class#first query method actually uses a Relation.
    # This means that this pattern is no longer possible:
    #    map = Map.first
    #    map.layers.to_a <- Raises ActiveRecord::StrictLoadingViolationError
    #
    # You'll need to call `map.strict_loading!(true, mode: :n_plus_one_only)`
    # (or `map.strict_loading!(false)` before loading the relation.

    module Relation
      def initialize(...)
        super(...)
        # Set strict loading on *all* relations.
        # This overrides the strict loading set in individual objects
        strict_loading!(klass.strict_loading_by_default)
      end
    end

    module Record
      def init_internals
        super
        # Here we set to the strict_loading_mode to :n_plus_one_only on new instances,
        # We have to do it in init_internals and *not* in after_initialize,
        # because after_initialize is called after the association loading sets it to :all.
        strict_loading!(self.class.strict_loading_by_default, mode: :n_plus_one_only)
      end
    end
  end
end
