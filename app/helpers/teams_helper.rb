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
                            data: {confirm: I18n.t(".teams.#{team_name}_detail.destroy")},
                            method: :delete,
                            id: 'deactivate-team-link'
    else
      I18n.t(".teams.deactivate_info.#{team_name}")
    end
  end

  def show_join_link_or_info(team)
    if team.code.present?
      t('teams.join.cannot_join_other_team', team_name: team.name)
    else
      link_to t('teams.join.heading'), join_teams_team_path(team.id), id: 'join-team-link'
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

  def move_to_directorate_back_link(team)
    link_to "Back", move_to_directorate_back_url(team), class: 'govuk-back-link'
  end

  def move_to_directorate_cancel_link(team)
    link_to "Cancel", move_to_directorate_back_url(team)
  end

  def move_to_directorate_back_url(team)
    move_to_directorate_team_path(team, business_group_id: team.business_group.id, directorate_id: team.directorate.id)
  end

  def move_to_business_group_back_link(team)
    link_to "Back", move_to_business_group_back_url(team), class: 'govuk-back-link'
  end

  def move_to_business_group_cancel_link(team)
    link_to "Cancel", move_to_business_group_back_url(team)
  end

  def move_to_business_group_back_url(team)
    move_to_business_group_team_path(team, business_group_id: team.business_group.id)
  end
end
