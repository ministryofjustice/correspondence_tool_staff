#rubocop:disable Metrics/ClassLength
class Case::BasePolicy < ApplicationPolicy

  attr_reader :user, :case, :failed_checks, :policy_workflow

  def initialize(user_obj = nil, kase_obj = nil, user: nil, kase: nil)
    @user = user_obj || user
    @case = kase_obj || kase
    raise Pundit::NotAuthorizedError, "must be logged in" if @user.nil?
    raise "Missing param" if @user.nil? || @case.nil?
  end

  # Use this as a standard way to re-use an existing policy in another policy
  # class, for example ICO SARs policies which can re-use the same login that's
  # in the SAR policies.
  def defer_to_existing_policy(policy_class, policy_name)
    policy_class.new(@user, @case).__send__(policy_name)
  end

  # PolicyScopes
  #
  # This inner Scope class is responsible for returning a collection of Case::Base records that the
  # user is able to work with.  It is normally called with the line:
  #
  #     scope = Pundit.policy_scope(user, Case::Base.all)
  #
  # which is in fact shorthand for:
  #     scope = Case::BasePolicy::Scope.new(user, Case::Base.all).resolve
  #
  class Scope
    attr_reader :user, :scope

    # This should be a list of all concrete case types.
    CASE_TYPES = [
        Case::FOI::Standard,
        Case::FOI::TimelinessReview,
        Case::FOI::ComplianceReview,
        Case::FOI::InternalReview,
        Case::SAR,
        Case::ICO::FOI,
        Case::ICO::SAR,
        Case::OverturnedICO::SAR,
        Case::OverturnedICO::FOI,
    ]

    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    # We resolve the scope for Case::BasePolicy by getting the scope on each of the sub-classes
    # and then combining them using or.
    # This is because a list/relation of different types (from Case::Base.all) resolves to
    # one policy(this one, Case::BasePolicy) for scope resolution
    def resolve
      scopes = CASE_TYPES.map do |case_type|
        "#{case_type}Policy::Scope".constantize.new(@user,@scope.where(type: case_type.to_s)).resolve
      end
      scopes.reduce { |memo, scope| memo.or(scope) }
    end
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

  def update_closure?
    clear_failed_checks
    check_can_trigger_event(:update_closure)
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

  def request_further_clearance?
    clear_failed_checks

    check_user_is_a_manager_for_case &&
      check_can_trigger_event(:request_further_clearance)
  end

  def new_case_link?
    clear_failed_checks
    check_can_trigger_event(:link_a_case) &&
        check_user_is_a_manager_for_case ||
        (!self.case.awaiting_responder? &&
            check_user_is_a_responder_for_case) ||
        check_user_is_an_approver_for_case
  end

  def destroy_case_link?
    # if we can make a link, we can destroy a link!
    new_case_link?
  end

  def can_view_attachments?
    clear_failed_checks
    # for flagged case, the state changes to pending_dacu_clearance as soon
    # as a response is added, and comes back to awaiting dacu dispatch if the
    # dd specialist uploads a response and clears, so we want the response
    # always to be visible.
    #
    # for unflagged case, we don't want the response to be visible when it's
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
    check_can_trigger_event(:reassign_user) &&
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
    user.manager? || user.responder?
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

  def unflag_for_clearance?
    clear_failed_checks
    check_can_trigger_event(:unflag_for_clearance)
  end

  def remove_clearance?
    clear_failed_checks
    check_case_workflow_is(:trigger) &&
      check_user_is_in_default_approving_team &&
        check_case_not_beyond_pending_dacu_clearance
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
        check_can_trigger_event(:respond)
  end

  def can_approve_or_escalate_case?
    clear_failed_checks
    check_case_requires_clearance &&
        check_user_is_in_current_team
  end

  def can_add_message_to_case?
    clear_failed_checks
    check_can_trigger_event(:add_message_to_case)
  end

  def approve?
    clear_failed_checks
    check_user_is_an_approver_for_case &&
        check_can_trigger_event(:approve)
  end

  def upload_responses?
    clear_failed_checks
    check_user_is_in_current_team &&
        check_can_trigger_event(:add_responses)
  end

  def upload_response_and_approve?
    clear_failed_checks
    check_user_is_in_current_team &&
        check_can_trigger_event(:upload_response_and_approve)
  end

  def upload_response_and_return_for_redraft?
    clear_failed_checks
    check_user_is_in_current_team &&
        check_can_trigger_event(:upload_response_and_return_for_redraft)
  end

  def user_is_admin?
    user.admin?
  end

  def only_flagged_for_disclosure_clearance?
    clear_failed_checks
    check_case_requires_clearance &&
        check_case_is_not_assigned_to_press_office &&
        check_case_is_not_assigned_to_private_office
  end

  def extend_for_pit?
    clear_failed_checks
    check_can_trigger_event(:extend_for_pit)
  end

  def remove_pit_extension?
    clear_failed_checks
    check_can_trigger_event(:remove_pit_extension)
  end

  def show?
    # This is just a catch-all in case we introduce a new type without a
    # corresponding policy for the new type. For safety sake, we do not allow
    # viewing
    raise Pundit::NotDefinedError.new("Please define 'show?' method in #{self.class}")
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


  check :user_is_assigned_manager_for_case do
    user == self.case.manager
  end

  check :user_is_a_manager_for_case do
    user.in? self.case.managing_team.users
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

  check :user_is_in_default_approving_team do
    user.in?(self.case.default_team_service.approving_team.users)
  end

  check :case_not_beyond_pending_dacu_clearance do
    self.case.current_state.in?(%w{unassigned awaiting_responder drafting pending_dacu_clearance })
  end

  check :case_workflow_is do | workflow |
    self.case.workflow == workflow.to_s
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
    self.case.drafting? || self.case.awaiting_dispatch?
  end

  check :escalation_deadline_has_expired do
    self.case.escalation_deadline < Date.today
  end

  check :within_escalation_deadline do
    !check_escalation_deadline_has_expired
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
    #team will not be present for closed case
    current_info.team.present? && @user.in?(current_info.team.users)
  end

  check :can_trigger_event do |event_name|
    self.case.state_machine.can_trigger_event?(
        event_name: event_name,
        metadata: { acting_user_id: user.id }
    )
  end
end
#rubocop:enable Metrics/ClassLength
