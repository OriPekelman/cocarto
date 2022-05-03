class ApplicationController < ActionController::Base

    around_action :switch_locale

    def switch_locale(&action)
    locale = params[:locale] || I18n.default_locale
    I18n.with_locale(locale, &action)
    end

    def extract_locale_frim_tld
        parsed_locale = request.host.split('.').last
        I18n.available_locales.map(&:to_s).include?(parsed_locale) ? parsed_locale: nil
    end

    def extract_locale_from_subdomain
        parsed_locale = request.subdomains.first
        I18n.available_locales.map(&:to_s).include?(parsed_locale) ? parsed_locale : nil
    end

    def default_url_options
        {locale: I18n.locale}
    end

end
