class ApplicationController < ActionController::Base
  # Pundit handles the authorization policies
  include Pundit::Authorization
  after_action :verify_authorized, except: :index # rubocop:disable Rails/LexicallyScopedActionFilter
  after_action :verify_policy_scoped, only: :index # rubocop:disable Rails/LexicallyScopedActionFilter

  before_action :set_sentry_user
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

  def set_sentry_user
    Sentry.set_user(id: current_user.id) if current_user.present?
  end

  def switch_locale(&action)
    locale = params.delete(:locale) || http_accept_language.compatible_language_from(I18n.available_locales)
    I18n.with_locale(locale, &action)
  end

  def default_url_options
    {locale: I18n.locale}
  end

  def after_sign_in_path_for(resource_or_scope)
    maps_path
  end

  def rescue_unauthorized
    yield
  rescue Pundit::NotAuthorizedError
    flash[:alert] = t("common.user_not_authorized")
    redirect_back(fallback_location: root_path)
  end
end
