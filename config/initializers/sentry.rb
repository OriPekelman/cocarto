# Sentry configuration for ruby on rails (see also _sentry.html.erb for js configuration)
if Rails.env.production? || ENV["COCARTO_DEBUG_SENTRY"].present?
  Sentry.init do |config|
    # sentry dsn is set automatically via the SENTRY_DN environment variable
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]
    config.traces_sample_rate = 1.0
    config.release = ENV.fetch("CONTAINER_VERSION") { "dev" } # Set by Scalingo, see https://doc.scalingo.com/platform/app/environment#runtime-environment-variables
    config.environment = Rails.env
  end
end
