class ApplicationController < ActionController::Base
  # Pundit handles the authorization policies
  include Pundit::Authorization

  around_action :rescue_unauthorized,
    :switch_locale # make sure locale is around all the rest

  def switch_locale(&action)
    locale = params[:locale] || http_accept_language.compatible_language_from(I18n.available_locales)
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
