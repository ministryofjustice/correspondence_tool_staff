class UsersController < ApplicationController
  before_action :set_team, only: [:create, :index, :new]

  def create
    @user = User.new(create_user_params)
    @user.password = SecureRandom.random_number(36**13).to_s(36)
    @user.password_confirmation = @user.password
    if @user.valid?
      if @team.present?
        role = @team.role
        @team.__send__(role.pluralize) << @user
      else
        @user.save
      end

      redirect_to users_path
    else
      render :new
    end

  end

  def index
    if @team.present?
      @users = @team.users
    else
      @users = User.all
    end
  end

  def new
    @user = User.new
  end

  private

  def create_user_params
    params.require(:user).permit(
      :full_name,
      :email,
    )
  end

  def set_team
    if params.key? :team_id
      @team = Team.find(params[:team_id])
    end
  end
end
