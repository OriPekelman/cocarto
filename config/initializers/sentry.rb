# Sentry configuration for ruby on rails (see also ApplicationController#set_sentry_user and _sentry.html.erb for js configuration)
if Rails.env.production? || ENV["COCARTO_DEBUG_SENTRY"].present?
  Sentry.init do |config|
    config.release = ENV.fetch("CONTAINER_VERSION") { "dev" } # Set by Scalingo, see https://doc.scalingo.com/platform/app/environment#runtime-environment-variables
    config.environment = Rails.env
    # sentry dsn is set automatically via the SENTRY_DN environment variable
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]
    config.sample_rate = 1 # Send all errors
    config.traces_sampler = lambda do |sampling_context|
      # cf https://docs.sentry.io/platforms/javascript/configuration/sampling/#custom-sampling-context-data
      if sampling_context[:parent_sampled].present?
        return sampling_context[:parent_sampled]
      end

      case sampling_context[:transaction_context]
      in {op: "websocket.server", name: "PresenceTrackerChannel#mouse_moved"}
        0.001 # only 1‰ of mouse_moved events
      else
        0.05 # 5% in general
      end
    end
    config.profiles_sample_rate = 1 # The profiles_sample_rate setting is relative to the traces_sample_rate setting.
  end
end
