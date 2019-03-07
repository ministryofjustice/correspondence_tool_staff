class Admin::UsersController < AdminController
  def index
    if @team.present?
      @users = @team.users
    else
      @users = User.all
                   .order(:full_name)
                   .page(params[:page]).per(100)
                   .decorate

      @active_users_count = User.active_users.count
    end
  end
end
