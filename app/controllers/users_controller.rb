class UsersController < ApplicationController
  before_action :set_team, only: [:create, :index, :new]

  def create
    @user = User.new(create_user_params)
    @user.password = SecureRandom.random_number(36**13).to_s(36)
    @user.password_confirmation = @user.password
    if @user.valid?
      if @team.present?
        role = validate_role
        @team.__send__(role.pluralize) << @user
        redirect_to team_path(id: @team.id)
      else
        @user.save
        redirect_to users_path
      end
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
    role = validate_role
    @role = role
  end

  private

  def validate_role
    if params.require(:role) == @team.role
      params[:role]
    else
      raise "Role parameter #{params[:role]} does not match team's roles."
    end
  end

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
