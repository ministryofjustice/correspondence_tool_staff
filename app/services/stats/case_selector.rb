module Stats
  class CaseSelector

    def self.ids_for_period(period_start, period_end)
      closed_case_ids = Case.closed.where(date_responded: [period_start..period_end]).pluck(:id)
      open_case_ids = Case.opened.pluck(:id)
      (closed_case_ids + open_case_ids).uniq
    end

  end
end

