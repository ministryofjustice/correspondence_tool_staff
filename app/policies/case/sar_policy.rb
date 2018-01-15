class Case::SARPolicy < Case::BasePolicy


  def can_respond?
    clear_failed_checks
    self.case.drafting? &&
        user.responding_teams.include?(self.case.responding_team)
  end
end
