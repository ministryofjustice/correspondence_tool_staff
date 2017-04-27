class CasePolicy

  attr_reader :user, :case

  def initialize(user, kase)
    @user = user
    @case = kase
  end

  def can_add_attachment?
    (self.case.drafting? ||
     self.case.awaiting_dispatch?) &&
      user.responding_teams.include?(self.case.responding_team)
  end

  def can_add_case?
    user.manager?
  end

  def can_assign_case?
    user.manager? && self.case.unassigned?
  end

  def can_accept_or_reject_case?
    self.case.awaiting_responder? &&
      user.responding_teams.include?(self.case.responding_team)
  end

  def can_close_case?
    user.manager? && self.case.responded?
  end

  def can_flag_for_clearance?
    user.manager?
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

  def can_view_case_details?
    user.manager? ||
      user.responding_teams.include?(self.case.responding_team)
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
        scope.select {|kase| user.responding_teams.include? kase.responding_team }
      elsif user.approver?
        scope.select {|kase| user.approving_teams.include? kase.approving_team }
      else
        []
      end
    end
  end
end
