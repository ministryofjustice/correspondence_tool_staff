class CaseRestartTheClockDecorator < Draper::Decorator
  decorates Case::Base
  delegate_all

  attr_accessor :restart_the_clock_date_dd, :restart_the_clock_date_mm, :restart_the_clock_date_yyyy

  def self.build(kase, params = nil)
    decorate(kase).tap do |decorator|
      return decorator unless params

      decorator.restart_the_clock_date_yyyy = params[:restart_the_clock_date_yyyy]
      decorator.restart_the_clock_date_mm = params[:restart_the_clock_date_mm]
      decorator.restart_the_clock_date_dd = params[:restart_the_clock_date_dd]
    end
  end
end
