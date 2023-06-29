module CaseDateManipulation
  def set_case_dates_back_by(kase, days_back)
    kase.update! received_date: days_back.before(kase.received_date),
                 external_deadline: days_back.before(kase.external_deadline),
                 internal_deadline: days_back.before(kase.internal_deadline),
                 escalation_deadline: days_back.before(kase.escalation_deadline)
    kase
  end
end
