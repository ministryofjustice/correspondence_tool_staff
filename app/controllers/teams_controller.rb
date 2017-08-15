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


  def team_params
    params.require(:team).permit(
      :name,
      :email,
      :team_lead
    )
  end

  private

  def set_team
    @team = Team.find(params[:id])
  end
end
