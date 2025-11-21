class CaseStopTheClockDecorator < Draper::Decorator
  decorates Case::Base
  delegate_all

  attr_accessor :stop_the_clock_date_dd, :stop_the_clock_date_mm, :stop_the_clock_date_yyyy
  attr_accessor :stop_the_clock_categories, :stop_the_clock_reason
end
