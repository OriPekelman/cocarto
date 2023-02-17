class Users::DeviseParentController < ApplicationController
  before_action :skip_authorization

  # TODO: Temporary fix for Devise and Turbo. Will be fixed in Devise 4.9.0.
  # See https://github.com/heartcombo/devise/pull/5548
  class Responder < ActionController::Responder
    def to_turbo_stream
      controller.render(options.merge(formats: :html))
    rescue ActionView::MissingTemplate => error
      if get?
        raise error
      elsif has_errors? && default_action
        render rendering_options.merge(formats: :html,
          status: :unprocessable_entity)
      else
        redirect_to navigation_location
      end
    end
  end

  self.responder = Responder
  respond_to :html, :turbo_stream
end
