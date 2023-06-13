class Users::SessionsController < Devise::SessionsController
  # Devise::SessionsController overrides

  # Allow sign in (sessions#new and sessions#create) if the current_user is actually anonymous
  skip_before_action :require_no_authentication, if: -> { warden.authenticated? && current_user&.anonymous? }

  def create
    if current_user&.anonymous?
      anonymous_user = current_user
      sign_out(anonymous_user)
      super { |real_user| real_user.reassign_from_anonymous_user(anonymous_user) }
    else
      super
    end
  end
end
