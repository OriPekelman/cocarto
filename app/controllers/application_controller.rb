class ApplicationController < ActionController::Base
  # Pundit handles the authorization policies
  include Pundit::Authorization
  after_action :verify_authorized, except: :index # rubocop:disable Rails/LexicallyScopedActionFilter
  after_action :verify_policy_scoped, only: :index # rubocop:disable Rails/LexicallyScopedActionFilter

  around_action :switch_locale, # make sure set_locale is first so that error messages are localized
    :restore_anonymous_session,
    :set_sentry_user,
    :rescue_unauthorized

  layout :modal_layout_if_needed

  def modal_layout_if_needed
    "modal" if turbo_frame_request_id == "modal"
  end

  def default_url_options
    {locale: I18n.locale}
  end

  def switch_locale(&action)
    locale = params.delete(:locale) || http_accept_language.compatible_language_from(I18n.available_locales)
    I18n.with_locale(locale, &action)
  end

  def restore_anonymous_session # See MapTokenAuthenticatable
    if warden.authenticated? && current_user.anonymous?
      current_user.store_tokens_array_in_session(session) # restore anonymous map tokens
    end
    yield
  end

  def set_sentry_user
    # Note: this is where we call `current_user` for the first time in each request.
    # It has side effects!
    # (e.g. if the found user is invited but not signed up yet)
    # See the Devise::FailureApp for flashes and redirections.
    if warden.authenticated?
      Sentry.set_user(id: current_user.anonymous? ? current_user.anonymous_tag : current_user.id)
    end
    yield
  end

  def rescue_unauthorized
    yield
  rescue Pundit::NotAuthorizedError
    flash[:alert] = t("common.user_not_authorized")
    if request.referer.present? && request.referer != request.url
      redirect_back(fallback_location: root_path)
    else
      redirect_to root_path
    end
  end
end
