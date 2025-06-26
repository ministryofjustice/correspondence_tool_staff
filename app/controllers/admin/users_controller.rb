class Admin::UsersController < AdminController
  def index
    @active_users_count = User.active_users.count

    if params[:search_for].present?
      search_string = "%#{params[:search_for].downcase}%"
      @users = User.where("LOWER(full_name) like ? OR LOWER(email) like ?", search_string, search_string)
                   .order(:full_name)
                   .page(params[:page]).per(10)
                   .decorate
    else
      @users = User.unscoped
                   .order(:full_name)
                   .page(params[:page]).per(100)
                   .decorate
    end
  end
end
