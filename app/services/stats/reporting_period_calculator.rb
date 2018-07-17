module Stats

  class ReportingPeriodCalculator


    attr_reader :period_start, :period_end

    def initialize(period_name: nil, period_start: nil, period_end: nil)
      @period_start = nil
      @period_end = nil
      if period_name.nil?
        instantiate_from_dates(period_start, period_end)
      else
        instantiate_from_period_name(period_name)
      end
    end

    def to_s
      mask = Settings.default_date_format
      "#{@period_start.strftime(mask)} to #{@period_end.strftime(mask)}"
    end

    private

    def instantiate_from_period_name(period_name)
      period_name = period_name.to_sym
      case period_name
        when :year_to_date
          @period_start = Date.today.beginning_of_year
          @period_end = Date.today
        when :quarter_to_date
          @period_start = Date.today.beginning_of_quarter
          @period_end = Date.today
        when :last_quarter
          @period_start = (Date.today - 3.months).beginning_of_quarter
          @period_end = (Date.today - 3.months).end_of_quarter
        when :last_month
          @period_start = (Date.today - 1.month).beginning_of_month
          @period_end = (Date.today - 1.month).end_of_month
        else
          raise ArgumentError.new 'Invalid period name specified'
      end
    end

    def instantiate_from_dates(p1, p2)
      unless p1.is_a?(Date) && p2.is_a?(Date)
        raise ArgumentError.new 'Period start and end must both be specified as Dates'
      end
      @period_start = p1
      @period_end = p2
    end
  end
end
