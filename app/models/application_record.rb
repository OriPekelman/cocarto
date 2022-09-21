class ApplicationRecord < ActiveRecord::Base
  include ActionView::RecordIdentifier # to access `dom_id`
  include TurboBroadcastableI18n

  self.abstract_class = true

  after_initialize do
    # We can’t set (yet?) the default strict loading *mode* in the app initializers.
    # strict_loading on single objects leads to many issues with new records or with pundit
    # See https://github.com/rails/rails/issues/41827#issuecomment-813282914 for some background
    strict_loading!(self.class.strict_loading_by_default, mode: :n_plus_one_only)
  end
end
