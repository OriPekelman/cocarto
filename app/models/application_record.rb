class ApplicationRecord < ActiveRecord::Base
  include ActionView::RecordIdentifier # to access `dom_id`
  include TurboBroadcastableI18n

  self.abstract_class = true
end
