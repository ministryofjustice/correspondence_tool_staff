module Cases
  #rubocop:disable Metrics/ClassLength
  class BasePolicy < ApplicationPolicy
    attr_accessor :user, :case

    def initialize(user, kase)
      @user = user
      @case = kase
    end


    def edit?
      clear_failed_checks
      check_user_is_a_manager
    end

    def update?
      edit?
    end

    def edit_case?
      edit?
    end

    def destroy?
      clear_failed_checks
      user.manager?
    end

    def destroy_case?
      destroy?
    end

    def confirm_destroy?
      destroy?
    end

    def can_view_attachments?
      clear_failed_checks
      # for flagged cases, the state changes to pending_dacu_clearance as soon
      # as a response is added, and comes back to awaiting dacu dispatch if the
      # dd specialist uploads a response and clears, so we want the response
      # always to be visible.
      #
      # for ged cases, we don't want the response to be visible when it's
      # in awaiting dispatch because the kilo is still workin gon it.
      #
      if self.case.does_not_require_clearance?
        check_case_is_responded_to_or_closed ||
          (check_user_in_responding_team)
      else
        true
      end
    end

    def can_add_attachment_to_flagged_and_unflagged_cases?
      clear_failed_checks
      responder_attachable? || approver_attachable?
    end

    def can_add_attachment?
      clear_failed_checks
      self.case.does_not_require_clearance? && responder_attachable?
    end

    def can_add_case?
      clear_failed_checks
      user.manager?
    end

    def can_assign_case?
      clear_failed_checks
      user.manager? && self.case.unassigned?
    end

    def can_accept_or_reject_approver_assignment?
      clear_failed_checks
      check_user_is_an_approver_for_case &&
        check_no_user_case_approving_assignments_are_accepted
    end

    def can_accept_or_reject_responder_assignment?
      clear_failed_checks
      self.case.awaiting_responder? &&
        user.responding_teams.include?(self.case.responding_team)
    end

    def assignments_reassign_user?
      clear_failed_checks
      check_case_is_not_responded_or_closed &&
        check_case_is_assigned_to_responder_or_approver_in_same_team_as_current_user
    end

    def assignments_execute_reassign_user?
      assignments_reassign_user?
    end

    def reassign_user?
      assignments_execute_reassign_user?
    end

    def can_close_case?
      clear_failed_checks
      user.manager? && self.case.responded?
    end

    def can_download_stats?
      user.manager?
    end

    def can_flag_for_clearance?
      clear_failed_checks
      check_user_is_a_manager || check_user_is_an_approver
    end

    def can_take_on_for_approval?
      clear_failed_checks
      check_case_not_already_taken_on_for_approval_by
    end

    def can_unaccept_approval_assignment?
      clear_failed_checks
      check_case_was_accepted_for_approval_by_user
    end

    def can_unflag_for_clearance?
      clear_failed_checks
      only_flagged_for_disclosure_clearance? &&
      (check_user_is_an_approver_for_case ||
        (check_user_is_a_manager && check_case_requires_clearance))
    end

    def can_remove_attachment?
      clear_failed_checks
      case self.case.current_state
      when 'awaiting_dispatch'
        user.responding_teams.include?(self.case.responding_team) &&
          self.case.assignments.approving.approved.none?
      else false
      end
    end

    def can_respond?
      clear_failed_checks
      self.case.awaiting_dispatch? &&
        self.case.response_attachments.any? &&
        user.responding_teams.include?(self.case.responding_team)
    end

    def approve_from_pending_dacu_clearance_to_awaiting_dispatch?
      clear_failed_checks

      check_case_is_not_assigned_to_press_office &&
        check_user_is_assigned_dacu_disclosure_approver
    end

    def approve_from_pending_dacu_clearance_to_pending_press_office_clearance?
      clear_failed_checks

      check_case_is_assigned_to_press_office &&
        check_user_is_assigned_dacu_disclosure_approver
    end

    def upload_response_and_approve_from_pending_dacu_clearance_to_pending_press_office_clearance?
      approve_from_pending_dacu_clearance_to_pending_press_office_clearance?
    end

    def upload_response_and_approve_from_pending_dacu_clearance_to_awaiting_dispatch?
      approve_from_pending_dacu_clearance_to_awaiting_dispatch?
    end

    def upload_response_and_approve_from_pending_private_office_clearance_to_awaiting_dispatch?
      clear_failed_checks
      check_user_is_assigned_private_office_approver
    end

    def approve_and_bypass_from_pending_dacu_clearance_to_awaiting_dispatch?
      clear_failed_checks

      check_user_is_an_approver_for_case &&
        check_case_is_assigned_to_press_office
    end

    def upload_response_approve_and_bypass_from_pending_dacu_clearance_to_awaiting_dispatch?
      clear_failed_checks

      check_user_is_an_approver_for_case &&
        check_case_is_assigned_to_press_office
    end

    def approve_from_pending_press_office_clearance_to_awaiting_dispatch?
      clear_failed_checks

      check_case_is_not_assigned_to_private_office &&
        check_user_is_assigned_press_office_approver
    end

    def approve_from_pending_press_office_clearance_to_pending_private_office_clearance?
      clear_failed_checks

      check_case_is_assigned_to_private_office &&
        check_user_is_assigned_press_office_approver
    end

    def approve_from_pending_private_office_clearance_to_awaiting_dispatch?
      clear_failed_checks

      check_user_is_assigned_private_office_approver
    end

    def can_approve_or_escalate_case?
      clear_failed_checks
      check_case_requires_clearance &&
        check_user_is_in_current_team
    end

    def can_view_case_details?
      clear_failed_checks
      if user.manager? || user.approver?
        true
      elsif user.responder?
        check_user_in_responding_team
      end
    end

    def can_add_message_to_case?
      clear_failed_checks
      check_case_is_not_closed && (check_user_is_a_manager || check_user_is_an_approver_for_case || check_user_is_a_responder_for_case)
    end

    def execute_response_approval?
      clear_failed_checks
      check_user_is_an_approver_for_case
    end

    def new_response_upload?
      clear_failed_checks
      check_user_is_in_current_team
    end

    def unflag_for_clearance_from_unassigned_to_unassigned?
      clear_failed_checks
      check_case_requires_clearance &&
        ( check_user_is_dacu_disclosure_approver ||
          check_user_is_assigned_approver_for_case ||
          check_user_is_a_manager
        )
    end

    def unflag_for_clearance_from_awaiting_responder_to_awaiting_responder?
      clear_failed_checks
      check_case_requires_clearance &&
        ( check_user_is_dacu_disclosure_approver ||
          check_user_is_assigned_approver_for_case ||
          check_user_is_a_manager
        )
    end

    def unflag_for_clearance_from_drafting_to_drafting?
      clear_failed_checks
      check_case_requires_clearance &&
        ( check_user_is_dacu_disclosure_approver ||
          check_user_is_assigned_approver_for_case ||
          check_user_is_a_manager
        )
    end

    def unflag_for_clearance_from_awaiting_dispatch_to_awaiting_dispatch?
      clear_failed_checks
      check_case_requires_clearance &&
        ( check_user_is_dacu_disclosure_approver ||
          check_user_is_assigned_approver_for_case ||
          check_user_is_a_manager
        )
    end

    def unflag_for_clearance_from_pending_dacu_clearance_to_awaiting_dispatch?
      clear_failed_checks
      check_case_requires_clearance_by_dacu_only &&
        ( check_user_is_a_manager || check_user_is_dacu_disclosure_approver )
    end

    def unflag_for_clearance_from_pending_dacu_clearance_to_pending_dacu_clearance?
      clear_failed_checks
      (check_case_is_assigned_to_press_office && check_user_is_press_office_approver) ||
        (check_case_is_assigned_to_private_office && check_user_is_private_office_approver)
    end


    def upload_responses?
      clear_failed_checks
      check_user_is_in_current_team
    end

    def upload_response_and_return_for_redraft_from_pending_dacu_clearance_to_drafting?
      clear_failed_checks
      check_case_is_assigned_to_dacu_disclosure &&
        check_user_is_assigned_dacu_disclosure_approver
    end

    def request_amends?
      clear_failed_checks

      (check_case_is_pending_press_office_clearance &&
       check_user_is_assigned_press_office_approver) ||
        (check_case_is_pending_private_office_clearance &&
         check_user_is_private_office_approver)
    end

    def execute_request_amends?
      clear_failed_checks

      (check_case_is_pending_press_office_clearance &&
       check_user_is_press_office_approver) ||
        (check_case_is_pending_private_office_clearance &&
         check_user_is_private_office_approver)
    end

    def request_amends_from_pending_press_office_clearance_to_pending_dacu_clearance?
      clear_failed_checks

      check_case_is_assigned_to_press_office &&
        check_user_is_assigned_press_office_approver
    end

    def request_amends_from_pending_private_office_clearance_to_pending_dacu_clearance?
      clear_failed_checks

      check_case_is_assigned_to_private_office &&
        check_user_is_assigned_private_office_approver
    end

    def add_response_to_flagged_case_from_drafting_to_pending_dacu_clearance?
      clear_failed_checks

      check_case_requires_clearance &&
        check_escalation_deadline_has_expired &&
        check_user_is_a_responder_for_case && check_case_is_not_closed
    end

    def user_is_admin?
      user.admin?
    end

    def assign_to_new_team_from_awaiting_responder_to_awaiting_responder?
      clear_failed_checks
      check_user_is_a_manager
    end

    def assign_to_new_team_from_drafting_to_awaiting_responder?
      clear_failed_checks
      check_user_is_a_manager
    end

    def only_flagged_for_disclosure_clearance?
      clear_failed_checks
        check_case_requires_clearance
        check_case_is_not_assigned_to_press_office &&
        check_case_is_not_assigned_to_private_office
    end

    private

    check :user_in_responding_team do
      user.responding_teams.include?(self.case.responding_team)
    end

    # def user_not_in_responding_team?
    #   !user_in_responding_team?
    # end

    def approver_attachable?
      self.case.pending_dacu_clearance? && self.case.approvers.first == user
    end

    def responder_attachable?
      clear_failed_checks
      check_escalation_deadline_has_expired && check_case_is_in_attachable_state && check_user_is_a_responder_for_case
    end


    check :user_is_an_approver do
      user.approver?
    end

    check :user_is_a_responder_for_case do
      user.responding_teams.include?(self.case.responding_team) &&
        !self.case.current_state.in?(['closed', 'responded'])
    end

    check :user_is_an_approver_for_case do
      user.in?(self.case.approving_team_users)
    end

    check :user_is_assigned_approver_for_case do
      user.in?(self.case.approvers)
    end

    check :user_is_assigned_dacu_disclosure_approver do
      @case.assignments.with_teams(BusinessUnit.dacu_disclosure).for_user(@user).present?
    end

    check :user_is_assigned_press_office_approver do
      @case.assignments.with_teams(BusinessUnit.press_office).for_user(@user).present?
    end

    check :user_is_assigned_private_office_approver do
      @case.assignments.with_teams(BusinessUnit.private_office).for_user(@user).present?
    end

    check :case_requires_clearance do
      self.case.requires_clearance?
    end

    check :case_requires_clearance_by_dacu_only do
      non_dacu_approver_assignments = self.case.approver_assignments - self.case.approver_assignments.where(team: BusinessUnit.dacu_disclosure)
      non_dacu_approver_assignments.none?
    end

    check :case_has_approvers do
      self.case.approvers.present?
    end

    check :case_has_no_other_approving_teams do
      (self.case.approving_teams - [user.approving_team]).empty?
    end

    check :case_has_another_approving_team do
      (self.case.approving_teams - [user.approving_team]).any?
    end

    check :user_is_a_case_approver do
      @user.in? self.case.approvers
    end

    check :case_is_assigned_to_responder_or_approver_in_same_team_as_current_user do
      user_teams_ids = user.teams.pluck(:id)
      approving_assignment_team_ids = self.case.assignments.approving.accepted.pluck(:team_id)
      responding_assignment_team_ids = self.case.assignments.responding.accepted.pluck(:team_id)
      (user_teams_ids & (approving_assignment_team_ids + responding_assignment_team_ids)).any?
    end

    check :user_is_not_case_approver do
      !@user.in? self.case.approvers
    end

    check :user_is_dacu_disclosure_approver do
      @user.in? BusinessUnit.dacu_disclosure.approvers
    end

    check :user_is_press_office_approver do
      @user.in? BusinessUnit.press_office.approvers
    end

    check :user_is_assigned_press_office_approver do
      @user == self.case.approver_assignments.with_teams(BusinessUnit.press_office).first&.user
    end

    check :user_is_assigned_private_office_approver do
      @user == self.case.approver_assignments.with_teams(BusinessUnit.private_office).first&.user
    end

    check :user_is_private_office_approver do
      @user.in? BusinessUnit.private_office.approvers
    end

    # check case_is_in_responder_attachable_state
    check :case_is_in_attachable_state do
      (self.case.drafting? || self.case.awaiting_dispatch?) &&
        self.case.assignments.approving.approved.none?
    end

    check :escalation_deadline_has_expired do
      self.case.escalation_deadline < Date.today
    end

    check :no_user_case_approving_assignments_are_accepted do
      !self.case.approver_assignments.with_teams(user.approving_team)
        .any?(&:accepted?)
    end

    check :case_is_responded_to_or_closed do
      self.case.responded? || self.case.closed?
    end

    check :case_not_already_taken_on_for_approval_by do
      team = @user.approving_team
      team.present? && !self.case.approver_assignments.map(&:team_id).include?(team.id)
    end

    check :case_was_accepted_for_approval_by_user do
      self.case.approver_assignments.where(user_id: @user.id).any?
    end

    check :case_is_not_responded_or_closed do
      !self.case.current_state.in?( ['responded', 'closed'] )
    end

    check :case_is_not_closed do
      !self.case.closed?
    end

    check :case_is_assigned_to_dacu_disclosure do
      BusinessUnit.dacu_disclosure.in? @case.approving_teams
    end

    check :case_is_assigned_to_press_office do
      BusinessUnit.press_office.in? @case.approving_teams
    end

    check :case_is_not_assigned_to_press_office do
      !BusinessUnit.press_office.in? @case.approving_teams
    end

    check :case_is_assigned_to_private_office do
      BusinessUnit.private_office.in? @case.approving_teams
    end

    check :case_is_not_assigned_to_private_office do
      !BusinessUnit.private_office.in? @case.approving_teams
    end

    check :case_is_pending_dacu_clearance do
      @case.pending_dacu_clearance?
    end

    check :case_is_pending_press_office_clearance do
      @case.pending_press_office_clearance?
    end

    check :case_is_pending_private_office_clearance do
      @case.pending_private_office_clearance?
    end

    check :case_is_assigned_to_press_office do
      BusinessUnit.press_office.in? @case.approving_teams
    end

    check :user_is_in_current_team do
      current_info = CurrentTeamAndUserService.new(@case)
      #team will not be present for closed cases
      current_info.team.present? && @user.in?(current_info.team.users)
    end

  end
  #rubocop:enable Metrics/ClassLength
end
