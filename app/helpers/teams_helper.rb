module TeamsHelper
  def sub_heading_for_teams(creating_team)
    if creating_team
      "New team"
    else
      "Editing team"
    end
  end
end
