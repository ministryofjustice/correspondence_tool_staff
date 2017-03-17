class CasePolicy

  attr_reader :user, :case

  def initialize(user, kase)
    @user = user
    @case = kase
  end

  def can_add_attachment?
    (self.case.drafting? || self.case.awaiting_dispatch?) && self.case.drafter == user
  end

  def can_add_case?
    user.manager?
  end

  def can_assign_case?
    user.manager? && self.case.unassigned?
  end

  def can_accept_or_reject_case?
    self.case.awaiting_responder? && self.case.drafter == user
  end

  def can_remove_attachment?
    case self.case.current_state
    when 'awaiting_dispatch' then self.case.drafter == user
    else false
    end
  end

  def can_respond?
    self.case.awaiting_dispatch? &&
      self.case.response_attachments.any? && self.case.drafter == user
  end

  def can_close_case?
    user.manager? && self.case.responded?
  end

  def can_view_case_details?
    user.manager? ||
      self.case.team.drafters.include?(user)
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
        scope.select {|kase| kase.responder == user }
      else
        []
      end
    end
  end
end
