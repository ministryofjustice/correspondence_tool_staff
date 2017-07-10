module CaseDateManipulation

  def set_dates_back_by(kase, period_in_past)
    kase.received_date = kase.received_date - period_in_past
    kase.external_deadline = kase.external_deadline - period_in_past
    kase.internal_deadline = kase.internal_deadline - period_in_past
    kase.escalation_deadline = kase.escalation_deadline - period_in_past
    kase.save!
    kase
  end

end
