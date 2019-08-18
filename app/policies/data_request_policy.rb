class DataRequestPolicy < ApplicationPolicy
  attr_reader :user, :case

  def initialize(user, kase)
    @case = kase
    super(user, kase)
  end

  def new?
    clear_failed_checks
    @case.is_offender_sar?
  end

  def create?
    clear_failed_checks
    @case.is_offender_sar?
  end
end
