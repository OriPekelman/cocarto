class PagesController < ApplicationController
  before_action :skip_authorization, :skip_policy_scope

  def legal
  end

  def presentation
  end
end
