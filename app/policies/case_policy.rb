class CasePolicy

  attr_reader :user, :case

  def initialize(user, kase)
    @user = user
    @case = kase
  end

  def can_view_attachments?
    # for flagged cases, the state changes to pending_dacu_clearance as soon as a response is
    # added, and comes back to awaiting dacu dispatch if the dd specialist uploads a response
    # and clears, so we want the response always to be visible.
    #
    # for unflagged cases, we don't want the response to be visible when it's in awaiting dispatch
    # because the kilo is still workin gon it.
    #
    if self.case.does_not_require_clearance?
      self.case.awaiting_dispatch?  && user_not_in_responding_team? ? false : true
    else
      true
    end
  end

  def can_add_attachment_to_flagged_and_unflagged_cases?
    responder_attachable? || approver_attachable?
  end

  def can_add_attachment?
    self.case.does_not_require_clearance? && responder_attachable?
  end

  def can_add_attachment_to_flagged_case?
    self.case.requires_clearance? && responder_attachable?
  end

  def can_upload_response_and_approve?
    self.case.requires_clearance? && approver_attachable?
  end

  def can_add_case?
    user.manager?
  end

  def can_assign_case?
    user.manager? && self.case.unassigned?
  end

  def can_accept_or_reject_approver_assignment?
    self.case.awaiting_approver? &&
      user.approving_teams.include?(self.case.approving_team)
  end

  def can_accept_or_reject_responder_assignment?
    self.case.awaiting_responder? &&
      user.responding_teams.include?(self.case.responding_team)
  end

  def can_reassign_approver?
    self.case.requires_clearance? &&
      self.case.approver.present? &&
      self.case.approver != @user
  end

  def can_close_case?
    user.manager? && self.case.responded?
  end

  def can_flag_for_clearance?
    !self.case.requires_clearance? &&
      (user.manager? || user.approver?)
  end

  def can_unflag_for_clearance?
    self.case.requires_clearance? &&
      (user.manager? || user.approver?)
  end

  def can_remove_attachment?
    case self.case.current_state
    when 'awaiting_dispatch'
      user.responding_teams.include?(self.case.responding_team)
    else false
    end
  end

  def can_respond?
    self.case.awaiting_dispatch? &&
      self.case.response_attachments.any? &&
      user.responding_teams.include?(self.case.responding_team)
  end

  def can_approve_case?
    self.case.pending_dacu_clearance? && self.case.approver == user
  end

  def can_view_case_details?
    if user.manager?
      true
    elsif user.responder?
      user.responding_teams.include?(self.case.responding_team)
    elsif user.approver?
      user.approving_teams.include?(self.case.approving_team)
    end
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    def resolve
      if user.manager?
        scope.all
      elsif user.responder?
        scope.with_team(*user.responding_teams)
      elsif user.approver?
        scope.with_team(*user.approving_teams)
      else
        Case.none
      end
    end
  end

  private

  def user_in_responding_team?
    @user.in?(self.case.responding_team.users)
  end

  def user_not_in_responding_team?
    !user_in_responding_team?
  end


  def approver_attachable?
    self.case.pending_dacu_clearance? && self.case.approver == user
  end

  def responder_attachable?
    responder_attachable_state? && user.responding_teams.include?(self.case.responding_team)
  end

  def responder_attachable_state?
    self.case.drafting? || self.case.awaiting_dispatch?
  end
end
