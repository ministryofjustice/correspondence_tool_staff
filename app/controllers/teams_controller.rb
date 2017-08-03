class TeamsController < ApplicationController



  def index
    @teams = BusinessGroup.all
  end

  def show
    @team = Team.find(params[:id])
    @children = @team.children
  end


  private

  def sub_team_types_for(team)
    case team.class
    when BusinessGroup
      'Directorate'
    when Directorate
      'Business Unit'
    else
      nil
    end
  end

  def sub_team_leads_for(team)
    case team.class
    when BusinessGroup
      'Directors'
    when Directorate
      'Deputy Directors'
    else
      nil
    end
  end
end
