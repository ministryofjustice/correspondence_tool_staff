class Admin::UsersController < AdminController
  def index
    if @team.present?
      @users = @team.users
    else
      @users = User.all.page(params[:page]).per(50).decorate
    end
  end
end
