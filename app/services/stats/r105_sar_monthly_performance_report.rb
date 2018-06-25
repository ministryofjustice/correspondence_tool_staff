module Stats
  class R105SarMonthlyPerformanceReport < BaseMonthlyPerformanceReport

    def self.title
      'Monthly report (SAR)'
    end

    def self.description
      'Shows number of SAR cases in each state by month'
    end

    def case_scope
      Case::SAR.where(created_at: @period_start..@period_end)
    end

  end
end
