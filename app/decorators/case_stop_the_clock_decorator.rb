class CaseStopTheClockDecorator < Draper::Decorator
  decorates Case::Base
  delegate_all

  attr_accessor :stop_reason
end
