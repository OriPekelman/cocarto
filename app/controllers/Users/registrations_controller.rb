class Users::RegistrationsController < DeviseInvitable::RegistrationsController
  # Devise::RegistrationsController overrides

  # Allow sign up (registrations#new and registrations#create) if the current_user is actually anonymous
  skip_before_action :require_no_authentication, if: -> { warden.authenticated? && current_user&.anonymous? }

  def create
    if current_user&.anonymous?
      anonymous_user = current_user
      super { |new_user| new_user.reassign_from_anonymous_user(anonymous_user) }
    else
      super
    end
  end

  # override from Devise::RegistrationsController
  def update_resource(resource, params)
    if params[:current_password].present?
      super
    else
      params.delete(:current_password)
      resource.update_without_password(params)
    end
  end

  def destroy
    # Prevent destroying a user with data. See #260 and #157.
    if resource.destroy
      super
    else
      redirect_back(fallback_location: :edit_user_registration_path, alert: t("common.failed", msg: resource.errors.full_messages.to_sentence))
    end
  end
end
