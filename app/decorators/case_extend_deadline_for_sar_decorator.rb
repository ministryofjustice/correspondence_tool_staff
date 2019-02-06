class CaseExtendDeadlineForSARDecorator < Draper::Decorator
  decorates Case::Base
  delegate_all

  attr_accessor :extension_period
  attr_accessor :reason_for_extending

  def allow_extension_period_selection?
    !object.deadline_extended? && object.extendable?
  end
end
