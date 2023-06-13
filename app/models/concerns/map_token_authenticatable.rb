module MapTokenAuthenticatable
  extend ActiveSupport::Concern
  # Handle User authentication via map token.
  # Enables anonymous access to the map page as well as API access to the exported layers. (e.g. geojson)
  #
  # If the passed token is found, an AnonymousUser is set up but it is not saved in the database, only in the session cookie.
  # The map_token is also added to another key of the session cookie.
  # Several map_tokens can be added like this; an anonymous user can access several maps,
  # and when converting to a real account or signing in, we can reassign these tokens to user_roles.
  #
  # See also MapsController#shared and User#assign_map_token.
  # See also ApplicationController#restore_anonymous_session and ApplicationCable::Connection#find_verified_user

  # The Warden Strategy; called by warden if a request is made, after the regular strategy.
  class Strategy < ::Warden::Strategies::Base
    def valid?
      params.key?(:token) || params.key?(:authkey) || request.headers.key?("X-Auth-Key")
    end

    def authenticate!
      api_token = params[:authkey] || request.headers["X-Auth-Key"]
      user_token = params[:token]
      token = user_token || api_token

      map_token = MapToken.find_by(token: token)
      if map_token.nil?
        fail!(I18n.t("api.bad_key"))
        return
      end

      user = AnonymousUser.new
      user.store_tokens_array_in_session(session)
      user.assign_map_token(map_token)
      success!(user)
    end
  end

  # Register the strategy with Warden and the Module with Devise
  # (Devise requires both identifiers to have the same name.)
  Warden::Strategies.add(:map_token_authenticatable, MapTokenAuthenticatable::Strategy)
  Devise.add_module(:map_token_authenticatable, strategy: true, model: "map_token_authenticatable")

  # Anonymous users are instances of AnonymousUser, and can never be stored in database.
  class AnonymousUser < ::User
    attr_accessor :anonymous_tag # identifies the user across queries (saved in the session cookie)
    attr_accessor :tokens_array  # stores the known map tokens (saved in the session cookie, too.)

    def initialize(anonymous_tag = nil)
      @anonymous_tag = anonymous_tag || SecureRandom.alphanumeric
      super(remember_me: false)
    end

    def anonymous? = true

    COCARTO_ANONYMOUS_MAP_TOKENS = "cocarto.anonymous.map_tokens"

    def store_tokens_array_in_session(session)
      session[COCARTO_ANONYMOUS_MAP_TOKENS] ||= []
      # NOTE: the tokens_array is shared state between the AnonymousUser and the Session serializer,
      # it is *not* copied here, and it is *mutable*.
      # Token strings added to the tokens_array will be stored in the session cookie.
      self.tokens_array = session[COCARTO_ANONYMOUS_MAP_TOKENS]
    end

    def map_tokens
      MapToken.where(token: tokens_array).to_a
    end

    def map_tokens=(tokens)
      self.tokens_array = tokens.map(&:token)
    end

    def to_global_id(options = {}) # Needed to identify the connection in ApplicationCable
      anonymous_tag
    end

    ## Methods overridden from User
    #
    def display_name
      I18n.t("users.anonymous")
    end

    def access_for_map(map)
      map_tokens.find { _1.map_id == map.id }
    end

    def assign_map_token(map_token)
      existing_map_token = map_tokens.find { _1.map_id == map_token.map_id }
      return if existing_map_token == map_token

      map_token.increment!(:access_count) # rubocop:disable Rails/SkipsModelValidations

      if existing_map_token.nil? # self does not already have access to the map
        tokens_array << map_token.token
      elsif map_token.is_stronger_than(existing_map_token) # self already has a lower access to the map
        tokens_array.delete(existing_map_token.token)
        tokens_array << map_token.token
      end
    end

    def maps
      Map.where(map_tokens: map_tokens)
    end
  end

  ## Overrides for the User class itself
  included do
    def anonymous? = false

    def reassign_from_anonymous_user(anonymous_user)
      accessed_map_tokens = MapToken.where(id: anonymous_user.map_tokens).includes(:map)
      accessed_map_tokens.each { |map_token| assign_map_token(map_token) }

      rows = Row.where(anonymous_tag: anonymous_user.anonymous_tag)
      rows.update(anonymous_tag: nil, author_id: id)
    end
  end

  module ClassMethods
    # Session serialization overload: we use the anonymous_tag to identify an AnonymousUser in the next request.
    # (This is stored in the "warden.user.user.key" key of the session cookie).
    COCARTO_ANONYMOUS = "cocarto_anonymous"

    def serialize_from_session(*args)
      return super unless args[0] == COCARTO_ANONYMOUS

      AnonymousUser.new(args[1])
    end

    def serialize_into_session(user)
      return super unless user.anonymous?

      [COCARTO_ANONYMOUS, user.anonymous_tag]
    end
  end
end
