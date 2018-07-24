class AdminController < ApplicationController
  layout "admin"

  private

  def authorize_admin
    authorize Case::Base, :user_is_admin?
  end
end
