# Require all Ruby files in the core_extensions directory
Dir[Rails.root.join("lib/core_extensions/*.rb")].each { |f| require f }

ActiveSupport.on_load(:active_record) do
  prepend CoreExtensions::StrictLoading::Record # self is ActiveRecord::Base
  ActiveRecord::Relation.prepend CoreExtensions::StrictLoading::Relation
end
