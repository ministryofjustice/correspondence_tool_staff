class Case::SAR::InternalReviewPolicy < Case::SAR::StandardPolicy

  class Scope < Case::SAR::InternalReviewPolicy::Scope
    def correspondence_type
      CorrespondenceType.sar_internal_review
    end
  end

  def can_respond?
    clear_failed_checks
    check_can_trigger_event(:respond)
  end

  def edit?
    super || user_is_an_approver_on_case?
  end

  def can_close_case?
    clear_failed_checks
    user.managing_teams.include?(self.case.managing_team)
  end

  def respond_and_close?
    clear_failed_checks
    user.managing_teams.include?(self.case.managing_team)
  end

  private

  def user_is_an_approver_on_case?
    self.case.approvers.include?(user)
  end
end

