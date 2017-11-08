class CaseExtendForPITDecorator < Draper::Decorator
  decorates Case
  delegate_all

  attr_accessor :extension_deadline_dd
  attr_accessor :extension_deadline_mm
  attr_accessor :extension_deadline_yyyy
  attr_accessor :reason_for_extending
end
