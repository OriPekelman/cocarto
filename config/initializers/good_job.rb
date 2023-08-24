Rails.application.config.after_initialize do
  GoodJob.on_thread_error = ->(exception) { Rails.error.report(exception, handled: false) } # Sentry registers as a standard ActiveSupport::ErrorReporter
end
