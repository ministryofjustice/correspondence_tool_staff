class TeamsController < ApplicationController
  before_action :set_team, only: [:show, :edit, :update]


  def index
    @teams = BusinessGroup.all
    authorize @teams.first
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
      redirect_to team_path(@team.parent)
    else
      render :edit
    end
  end

  def new
    klass = case params[:type]
            when 'bu'
              BusinessUnit
            when 'dir'
              Directorate
            when 'bg'
              BusinessGroup
            else
              raise ArgumentError.new('Invalid team type parameter')
            end
    @team = klass.new
    @team.team_lead = ''
    @team.parent_id = params[:parent_id].to_i
  end

  def create
    authorize Team.first

    @team = BusinessUnit.new(new_team_params)
    if @team.save
      flash[:notice] = 'Team created'
      redirect_to team_path(@team.parent_id)
    else
      render :new
    end
  end


  def team_params
    params.require(:team).permit(
      :name,
      :email,
      :team_lead
    )
  end

  def new_team_params
    params.require(:team).permit(
                           :name,
                           :email,
                           :team_lead,
                           :parent_id
    )
  end

  private

  def set_team
    @team = Team.find(params[:id])
  end
end
