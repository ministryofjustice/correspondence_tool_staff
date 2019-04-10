class UsersController < ApplicationController

  before_action :set_team, only: [:create, :new, :edit, :update, :confirm_destroy]

  def show
    @user = User.find params[:id]
    unpaginated_cases = UserActiveCaseCountService.new.active_cases_for_user(@user)
    if download_csv_request?
      @cases = unpaginated_cases.decorate
    else
      @cases = unpaginated_cases.page(params[:page]).decorate
    end
    respond_to do |format|
      format.html     { render :show }
      format.csv do
        send_csv_cases @user.full_name.downcase.tr(' ', '_')
      end
    end
  end

  def create
    service = UserCreationService.new(team: @team, params: create_user_params)
    service.call
    @user = service.user
    case service.result
    when :ok
      flash[:notice] = 'User created'
      redirect_to team_path(id: @team.id)
    when :existing_ok
      flash[:notice] = 'Existing user added to team'
      redirect_to team_path(id: @team.id)
    else
      render :new
    end
  end

  def new
    @user = User.new
    role = validate_role
    @role = role
  end

  def edit
    @user = User.find params[:id]
    @role = @team.role
  end

  def update
    @user = User.find params[:id]
    if @user.update(create_user_params)
      flash[:notice] = 'User details updated'
      redirect_to team_path(id: @team.id)
    else
      render :edit
    end
  end

  def destroy
    authorize current_user
    service = UserDeletionService.new(params, current_user)
    service.call
    case service.result
    when :ok
      flash[:notice] = I18n.t('devise.registrations.destroyed')
    when :has_live_cases
      flash[:alert] = I18n.t('devise.registrations.has_live_cases')
    else
      flash[:alert] = I18n.t('devise.registrations.error')
    end
    redirect_to team_path(params[:team_id])
  end

  def confirm_destroy
    @user = User.find params[:id]
    @team = Team.find params[:team_id]
    render :confirm_destroy
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
