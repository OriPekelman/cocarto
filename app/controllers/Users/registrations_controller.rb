class Users::RegistrationsController < DeviseInvitable::RegistrationsController
  # Customize User deletion
  def destroy
    if resource.destroy
      super
    else
      # Prevent destroying a user with data. See #260 and #157.
      redirect_back(fallback_location: :edit_user_registration_path, alert: t("common.failed", msg: resource.errors.full_messages.to_sentence))
    end
  end
end
