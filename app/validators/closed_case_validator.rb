class ClosedCaseValidator < ActiveModel::Validator

  def validate(rec)
    if rec.prepared_for_close? || rec.current_state == 'closed'
      validate_date_responded(rec)
      validate_outcome(rec)
      validate_refusal_reason(rec)
    end
  end

  private

  def validate_date_responded(rec)
    if rec.date_responded.blank?
      rec.errors.add(:date_responded, "can't be blank")
    else
      if rec.date_responded > Date.today
        rec.errors.add(:date_responded, "can't be in the future")
      end
    end
  end

  def validate_outcome(rec)
    rec.errors.add(:outcome, "can't be blank") if rec.outcome.blank?
  end

  def validate_refusal_reason(rec)
    if rec.outcome&.requires_refusal_reason?
      if rec.refusal_reason.blank?
        rec.errors.add(:refusal_reason, 'must be present for the specified outcome')
      end
    else
      if rec.refusal_reason.present?
        rec.errors.add(:refusal_reason, 'cannot be present for the specified outcome')
      end
    end
  end
end


