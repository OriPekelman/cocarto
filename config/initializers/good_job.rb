Rails.application.config.after_initialize do
  GoodJob.active_record_parent_class = "ApplicationRecord"

  GoodJob.on_thread_error = ->(exception) { Rails.error.report(exception, handled: false) } # Sentry registers as a standard ActiveSupport::ErrorReporter

  GoodJob::Job.strict_loading_by_default = false # The GoodJob::Jobs#show page in the dashboard has N+1 queries ¯\_(ツ)_/¯
end
