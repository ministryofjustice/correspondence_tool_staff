class CaseExtendSARDeadlineDecorator < Draper::Decorator
  decorates Case::SAR::Standard
  delegate_all

  attr_accessor :extension_period
  attr_accessor :reason_for_extending

  def allow_extension_period_selection?
    !object.deadline_extended? && object.deadline_extendable?
  end

  def time_unit_string(time_period)
    object.deadline_calculator.time_units_desc_for_deadline(time_period > 1)
  end 
end
