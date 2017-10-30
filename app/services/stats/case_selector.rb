module Stats
  class CaseSelector

    def self.ids_for_period(period_start, period_end)
      closed_case_ids = Case.closed.where(date_responded: [period_start..period_end]).pluck(:id)
      open_case_ids = Case.opened.pluck(:id)
      (closed_case_ids + open_case_ids).uniq
    end

    def self.ids_for_cases_received_in_period(period_start, period_end)
      Case.where(received_date: [period_start..period_end]).pluck(:id)
    end

  end
end

