class CasePolicy

  attr_reader :user, :case

  def initialize(user, kase)
    @user = user
    @case = kase
  end

  def can_add_case?
    user.assigner?
  end

  def can_close_case?
    user.assigner? && self.case.responded?
  end
end
