class PagesController < ApplicationController
  before_action :skip_authorization, :skip_policy_scope

  def legal
  end

  def legal_conditions
  end

  def legal_data
  end

  def presentation
  end
end
