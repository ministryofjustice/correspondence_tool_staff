module TeamsHelper
  def sub_heading_for_teams(creating_team)
    if creating_team
      "New team"
    else
      "Editing team"
    end
  end

  def show_deactivate_link_or_info(current_user, team)
    team_name = team.class.name.underscore
    if Pundit.policy(current_user, team).destroy?
      link_to "Deactivate #{team.pretty_type}", team_path(team.id),
                            data: {:confirm => I18n.t(".teams.#{team_name}_detail.destroy")},
                            method: :delete,
                            id: 'deactivate-team-link'
    else
      I18n.t(".teams.deactivate_info.#{team_name}")
    end
  end
end
