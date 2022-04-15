class RespondedCaseValidator < ActiveModel::Validator

  def validate(rec)
    if rec.prepared_for_respond?
      validate_responded_date(rec)
    end
  end

  private

  def validate_responded_date(rec)
    if rec.date_responded.blank?
      rec.errors.add(:date_responded, :blank)
    else
      if rec.date_responded < rec.received_date
        rec.errors.add(:date_responded, :before_received)
      elsif rec.date_responded > Time.current.to_date
        rec.errors.add(:date_responded, :future)
      end
    end
  end
end
