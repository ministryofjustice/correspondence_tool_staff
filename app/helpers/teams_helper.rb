module TeamsHelper
  def sub_heading_for_teams(creating_team)
    if creating_team
      "New team"
    else
      "Editing team"
    end
  end

  def show_deactivate_link_or_info(current_user, team)
    if Pundit.policy(current_user, team).destroy?
      link_to "Deactivate #{team.type.humanize}", team_path(team.id),
                            data: {:confirm => I18n.t('.teams.directorate_detail.destroy')},
                            method: :delete,
                            id: 'deactivate-team-link'
    else
      "To deactivate this #{team.type.humanize} you need to first deactivate all #{team.children.first.type.humanize} within it."
    end
  end
end
