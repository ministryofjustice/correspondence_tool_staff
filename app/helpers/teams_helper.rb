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
      link_to "Deactivate #{team.pretty_type&.downcase}", team_path(team.id),
                            data: {:confirm => I18n.t(".teams.#{team_name}_detail.destroy")},
                            method: :delete,
                            id: 'deactivate-team-link'
    else
      I18n.t(".teams.deactivate_info.#{team_name}")
    end
  end

  def join_teams_back_link(team)
    link_to "Back", join_teams_back_url(team), class: 'govuk-back-link'
  end

  def join_teams_cancel_link(team)
    link_to "Cancel", join_teams_back_url(team)
  end

  def join_teams_back_url(team)
    join_teams_team_path(team, business_group_id: team.business_group.id, directorate_id: team.directorate.id)
  end

  def team_breadcrumb(team, include_self = false)
    return "Business group" unless team.parent
    teams = []
    teams << team.parent&.parent
    teams << team.parent
    teams << team if include_self
    crumb = teams.compact.map { |t| team_link(t) }
    output = crumb.join(" > ").html_safe + " >".html_safe
  end

  def team_link(team)
    link_to team.name, team_path(team.id)
  end
end
