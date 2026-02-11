class CaseExtendSARDeadlineDecorator < Draper::Decorator
  decorates Case::Base
  delegate_all

  NUMBER_TO_WORDS = %w[zero one two three four five six seven eight nine ten].freeze

  attr_accessor :extension_period, :reason_for_extending

  def allow_extension_period_selection?
    !object.deadline_extended? && object.deadline_extendable?
  end

  def time_period_description(time_period)
    "#{time_period_string(time_period)} #{time_unit_string(time_period)}"
  end

private

  def time_period_string(time_period)
    time_period.to_i <= 10 ? NUMBER_TO_WORDS[time_period.to_i] : time_period.to_s
  end

  def time_unit_string(time_period)
    object.deadline_calculator.time_units_desc_for_deadline(time_period)
  end
end
