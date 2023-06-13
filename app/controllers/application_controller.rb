class ApplicationController < ActionController::Base
  # Pundit handles the authorization policies
  include Pundit::Authorization
  after_action :verify_authorized, except: :index # rubocop:disable Rails/LexicallyScopedActionFilter
  after_action :verify_policy_scoped, only: :index # rubocop:disable Rails/LexicallyScopedActionFilter

  before_action :restore_anonymous_session, :set_sentry_user
  around_action :rescue_unauthorized,
    :switch_locale # make sure locale is around all the rest

  def render_to_body(options = {})
    # When the request is made to be displayed in a turbo-frame modal, we wrap in a specific component.
    if turbo_frame_request_id == "modal"
      ModalComponent.new.with_content(super).render_in(view_context)
    else
      super
    end
  end

  def restore_anonymous_session # See MapTokenAuthenticatable
    if warden.authenticated? && current_user.anonymous?
      current_user.store_tokens_array_in_session(session) # restore anonymous map tokens
    end
  end

  def set_sentry_user
    if warden.authenticated?
      Sentry.set_user(id: current_user.anonymous? ? current_user.anonymous_tag : current_user.id)
    end
  end

  def switch_locale(&action)
    locale = params.delete(:locale) || http_accept_language.compatible_language_from(I18n.available_locales)
    I18n.with_locale(locale, &action)
  end

  def default_url_options
    {locale: I18n.locale}
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
