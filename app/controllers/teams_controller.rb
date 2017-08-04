class TeamsController < ApplicationController

  def index
    @teams = BusinessGroup.all
    authorize @teams.first
  end

  def show
    @team = Team.find(params[:id])
    authorize @team
    @children = @team.children
  end

  def edit
    @team = Team.find(params[:id])
    authorize @team
  end

  def update
    @team = Team.find(params[:id])
    if @team.update(team_params)
      flash.now[:notice] = 'Team details updated'
      redirect_to edit_team_path(@team.parent)
    else
      render :edit
    end
  end


  def team_params
    params.require(:team).permit(
      :name,
      :email
    )
  end
end
