class ApplicationRecord < ActiveRecord::Base
  include ActionView::RecordIdentifier # to access `dom_id`
  include TurboBroadcastableI18n

  self.abstract_class = true

  # Basic “warnings" management reusing the ActiveModel::Errors class
  # It does not change the validation behaviour;
  # it’s up to subclasses to populate warnings and to the calling code to make something out of it.
  # This is useful for importing data, which may succeed with warnings.
  def warnings
    @warnings ||= ActiveModel::Errors.new(self)
  end
end
