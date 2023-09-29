class Users::DeviseParentController < ApplicationController
  before_action :skip_authorization

  before_action :configure_permitted_parameters

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:display_name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:display_name])
    devise_parameter_sanitizer.permit(:accept_invitation, keys: [:display_name])
  end
end
