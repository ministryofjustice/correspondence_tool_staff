class TeamsController < ApplicationController
  before_action :set_team, only: [:show, :edit, :update]


  def index
    @teams = policy_scope(Team)
    unless current_user.manager?
      render :teams_for_user
    else
      render :index
    end
  end

  def show
    authorize @team
    @children = @team.children
  end

  def edit
    authorize @team
  end

  def update
    authorize @team

    if @team.update(team_params)
      flash[:notice] = 'Team details updated'
      redirect_to post_update_redirect_destination
    else
      render :edit
    end
  end

  def new
    authorize Team
    klass = get_class_from_team_type
    @team = klass.new
    @team.team_lead = ''
    @team.parent_id = params[:parent_id].to_i
    @team_type = params[:team_type]
  end

  def create
    authorize Team.first
    klass = get_class_from_team_type
    @team = klass.new(new_team_params)
    @team.parent_id = nil if @team.is_a?(BusinessGroup)
    if @team.save
      flash[:notice] = 'Team created'
      redirect_to params[:team_type] == 'bg' ? teams_path : team_path(@team.parent_id)
    else
      @team_type = params[:team_type]
      render :new
    end
  end


  def team_params
    params.require(:team).permit(
      :name,
      :email,
      :team_lead,
      :role
    )
  end

  def new_team_params
    params.require(:team).permit(
                           :name,
                           :email,
                           :team_lead,
                           :parent_id,
                           :role
    )
  end

  private

  def post_update_redirect_destination
    if current_user.manager?
      params[:team_type] == 'bg' ? teams_path : team_path(@team.parent_id)
    else
      team_path(@team.id)
    end
  end

  def get_class_from_team_type
    case params[:team_type]
    when 'bu'
      BusinessUnit
    when 'dir'
      Directorate
    when 'bg'
      BusinessGroup
    else
      raise ArgumentError.new('Invalid team type parameter')
    end
  end

  def set_team
    @team = Team.find(params[:id])
  end
end
