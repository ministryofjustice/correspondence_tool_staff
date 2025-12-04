class CaseRestartTheClockDecorator < Draper::Decorator
  decorates Case::Base
  delegate_all

  attr_accessor :restart_the_clock_date, :restart_the_clock_date_dd, :restart_the_clock_date_mm, :restart_the_clock_date_yyyy
end
