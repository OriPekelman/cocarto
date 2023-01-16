class MainController < ApplicationController
  def index
    skip_policy_scope
  end

  def legal
    skip_authorization
  end
end
