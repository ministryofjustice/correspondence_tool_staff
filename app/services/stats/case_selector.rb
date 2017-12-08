module Stats
  class CaseSelector

    def self.ids_for_period(kase, period_start, period_end)
      closed_case_ids = kase.closed.where(date_responded: [period_start..period_end]).pluck(:id)
      open_case_ids = kase.opened.pluck(:id)
      (closed_case_ids + open_case_ids).uniq
    end

    def self.ids_for_cases_received_in_period(kase, period_start, period_end)
    kase.where(received_date: [period_start..period_end]).pluck(:id)
    end

    def self.ids_for_period_appeals(kase, period_start, period_end)
      closed_case_ids =  kase.closed.where(date_responded: [period_start..period_end]).pluck(:id)
      open_case_ids = kase.opened.pluck(:id)
      (closed_case_ids + open_case_ids).uniq
    end

    def self.ids_for_appeals_received_in_period(kase, period_start, period_end)
      kase.where(received_date: [period_start..period_end]).pluck(:id)
    end

  end
end
