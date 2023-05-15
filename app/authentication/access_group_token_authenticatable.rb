module AccessGroupTokenAuthenticatable
  extend ActiveSupport::Concern

  # Handle authentication via an access_group token.
  # Enables anonymous access to the maps page as well as API access to the exported layers. (e.g. geojson)
  #
  # If a group if found with the passed token, a new User is set up.
  #
  # See also MapsController#shared and User#assign_access_group.

  class Strategy < ::Warden::Strategies::Base
    def valid?
      params.key?(:token) || params.key?(:authkey) || request.headers.key?("X-Auth-Key")
    end

    def authenticate!
      api_token = params[:authkey] || request.headers["X-Auth-Key"]
      user_token = params[:token]
      token = user_token || api_token

      access_group = AccessGroup.find_by(token: token)
      if access_group.nil?
        fail!(I18n.t("api.bad_key"))
        return
      end

      user = User.new(access_groups: [access_group], remember_me: false)
      if user_token.present?
        user.save!
      end

      success!(user)
    end
  end

  # Register the strategy with Warden and the Module with Devise
  # (Devise requires both identifiers to have the same name.)
  Warden::Strategies.add(:access_group_token_authenticatable, AccessGroupTokenAuthenticatable::Strategy)
  Devise.add_module(:access_group_token_authenticatable, strategy: true, model: "access_group_token_authenticatable")
end
