module UsersHelper
  def unassign_or_deactivate_link(user, team)
    if user.has_live_cases_for_team?(team)
      link_to "Deactivate team member", confirm_destroy_team_user_path(team.id, user.id),
              class: "button-secondary button-left-spacing",
              id: "deactivate-user-button"
    else
      link_to "Deactivate team member", team_user_path(team.id, user.id),
              method: :delete,
              class: "button-secondary button-left-spacing",
              id: "deactivate-user-button"
    end
  end
end
