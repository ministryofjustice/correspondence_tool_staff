class CaseStopTheClockDecorator < Draper::Decorator
  decorates Case::Base
  delegate_all

  attr_accessor :stop_the_clock_date_dd, :stop_the_clock_date_mm, :stop_the_clock_date_yyyy, :stop_the_clock_categories, :stop_the_clock_reason

  def self.build(kase, params = nil)
    decorate(kase).tap do |decorator|
      return decorator unless params

      decorator.stop_the_clock_categories = params[:stop_the_clock_categories]
      decorator.stop_the_clock_reason = params[:stop_the_clock_reason]
      decorator.stop_the_clock_date_yyyy = params[:stop_the_clock_date_yyyy]
      decorator.stop_the_clock_date_mm = params[:stop_the_clock_date_mm]
      decorator.stop_the_clock_date_dd = params[:stop_the_clock_date_dd]
    end
  end
end
