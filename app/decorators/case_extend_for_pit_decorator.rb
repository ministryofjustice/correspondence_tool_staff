class CaseExtendForPITDecorator < Draper::Decorator
  decorates Case::Base
  delegate_all

  attr_accessor :extension_deadline_dd, :extension_deadline_mm, :extension_deadline_yyyy, :reason_for_extending
end
