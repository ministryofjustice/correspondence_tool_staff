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

end
