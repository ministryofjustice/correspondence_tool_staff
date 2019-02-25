class Workflows::Predicates
  def initialize(user:, kase:)

    @user = user
    @kase = kase
  end

  def responder_is_member_of_assigned_team?
    if @kase.responding_team
      @kase.responding_team.users.include?(@user)
    else
      false
    end
  end

  def responder_is_member_of_assigned_team_and_not_overturned?
    responder_is_member_of_assigned_team? && not_overturned?
  end

  def user_is_assigned_responder?
    @kase.responder == @user
  end

  def user_is_approver_on_case?
    @user.in?(@kase.approvers)
  end

  def user_is_in_approving_team_for_case?
    @user.in?(@kase.approving_team_users)
  end

  def case_can_be_unflagged_for_clearance?
    case_can_be_unflagged_for_clearance_by_disclosure_specialist? ||
      case_can_be_unflagged_for_clearance_by_press_officer? ||
      case_can_be_unflagged_for_clearance_by_private_officer?
  end

  def case_can_be_unflagged_for_clearance_by_disclosure_specialist?
    approver_assignments = @kase.assignments.approving
    disclosure           = BusinessUnit.dacu_disclosure

    @user.approving_team == disclosure &&
      approver_assignments.count == 1 &&
      approver_assignments.first.team == disclosure &&
      (approver_assignments.first.accepted? ||
       approver_assignments.first.pending?)
  end

  def case_can_be_unflagged_for_clearance_by_press_or_private?
    case_can_be_unflagged_for_clearance_by_press_officer? ||
      case_can_be_unflagged_for_clearance_by_private_officer?
  end

  def case_can_be_unflagged_for_clearance_by_press_officer?
    approver_assignments = @kase.assignments.approving
    press_office         = BusinessUnit.press_office

    @user.approving_team == press_office &&
      approver_assignments.with_teams(press_office).any?
  end

  def case_can_be_unflagged_for_clearance_by_private_officer?
    approver_assignments = @kase.assignments.approving
    private_office       = BusinessUnit.private_office

    @user.approving_team == private_office &&
      approver_assignments.with_teams(private_office).any?
  end

  def user_is_assigned_disclosure_specialist?
    @kase.assignments.with_teams(BusinessUnit.dacu_disclosure).for_user(@user).present?
  end

  def user_is_assigned_press_officer?
    @kase.assignments.with_teams(BusinessUnit.press_office).for_user(@user).present?
  end

  def user_is_assigned_private_officer?
    @kase.assignments.with_teams(BusinessUnit.private_office).for_user(@user).present?
  end

  def can_edit_closure
    @kase.info_held_status_id.present?
  end

  def case_is_assigned_to_responder_or_approver_in_same_team_as_current_user
    user_teams_ids = @user.teams.pluck(:id)
    approving_assignment_team_ids = @kase.assignments.approving.accepted.pluck(:team_id)
    responding_assignment_team_ids = @kase.assignments.responding.accepted.pluck(:team_id)
    (user_teams_ids & (approving_assignment_team_ids + responding_assignment_team_ids)).any?
  end

  def can_create_new_overturned_ico?
    @kase.ico? &&
        @kase.ico_decision == 'overturned' &&
        overturned_enabled?(@kase) &&
        @kase.lacks_overturn?
  end

  def not_overturned?
    !@kase.overturned_ico?
  end

  def overturned_editing_enabled?
    if @kase.overturned_ico?
      FeatureSet.edit_overturned.enabled?
    else
      true
    end
  end

  def overturned_editing_enabled_and_responder_in_assigned_team?
    responder_is_member_of_assigned_team? && overturned_editing_enabled?
  end

  def has_pit_extension?
    @kase.has_pit_extension?
  end

  # Use of try rather than direct method call because
  # deadline_extended? is only available for
  # Case::SAR and should be false for non-SAR cases
  def has_sar_deadline_extension?
    @kase.try(:deadline_extended?)
  end

  # Use of try rather than direct method call because
  # deadline_extendable? is only available for
  # Case::SAR and should be false for non-SAR cases
  def deadline_does_not_exceed_max_deadline?
    @kase.try(:deadline_extendable?)
  end

  def case_extended_and_user_in_approving_team?
    has_sar_deadline_extension? && user_is_in_approving_team_for_case?
  end

  def assigned_team_member_and_case_outside_escalation_period?
    responder_is_member_of_assigned_team? && @kase.outside_escalation_deadline?
  end


  private

  def overturned_enabled?(kase)
    if kase.original_case.sar?
      FeatureSet.overturned_sars.enabled?
    elsif kase.original_case.foi?
      FeatureSet.overturned_fois.enabled?
    else
      false
    end
  end
end
