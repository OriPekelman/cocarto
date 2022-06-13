class ApplicationController < ActionController::Base
  # Pundit handles the authorization policies
  include Pundit::Authorization

  around_action :switch_locale

  def switch_locale(&action)
    locale = params[:locale] || http_accept_language.compatible_language_from(I18n.available_locales)
    I18n.with_locale(locale, &action)
  end

  def default_url_options
    {locale: I18n.locale}
  end

  def after_sign_in_path_for(resource_or_scope)
    layers_path
  end
end
