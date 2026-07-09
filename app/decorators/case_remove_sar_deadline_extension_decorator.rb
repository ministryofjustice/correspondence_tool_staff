class CaseRemoveSARDeadlineExtensionDecorator < Draper::Decorator
  decorates Case::Base
  delegate_all

  attr_accessor :reason_for_removing_extension

  # The external deadline the case reverts to once the extension is removed.
  def reverted_deadline
    @reverted_deadline ||= object.recalculate_deadline_without_extensions
  end

  # True when removing the extension would put the deadline in the past,
  # i.e. completing the journey makes the case late.
  def removal_makes_case_late?
    reverted_deadline.past?
  end
end
