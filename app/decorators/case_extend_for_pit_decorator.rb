class CaseExtendForPITDecorator < Draper::Decorator
  decorates Case
  delegate_all

  attr_accessor :external_deadline_dd
  attr_accessor :external_deadline_mm
  attr_accessor :external_deadline_yyyy
  attr_accessor :reason_for_extending
end
