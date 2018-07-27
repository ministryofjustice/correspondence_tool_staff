class Admin::UsersController < ApplicationController
  before_action :authorize_admin

  def index
    if @team.present?
      @users = @team.users
    else
      @users = User.all.page(params[:page]).per(50).decorate
    end
  end
end
