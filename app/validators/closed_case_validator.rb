class ClosedCaseValidator < ActiveModel::Validator

  def validate(rec)
    if rec.prepared_for_close? || rec.current_state == 'closed'
      if validate_closure_details?(rec) && rec.class == Case::FOI
        validate_date_responded(rec)
        validate_info_held_status(rec)
        validate_outcome(rec)
        validate_refusal_reason(rec)
        validate_exemptions(rec)
      else
        validate_date_responded(rec)
      end
    end
  end

  private

  def validate_closure_details?(rec)
    if rec.date_responded.blank?
      true
    else
      rec.date_responded > Date.new(2017, 11, 7)
    end
  end

  def validate_info_held_status(rec)
    if rec.info_held_status.nil?
      rec.errors.add(:info_held_status, "can't be blank")
    end
  end

  def validate_date_responded(rec)
    if rec.date_responded.blank?
      rec.errors.add(:date_responded, "can't be blank")
    else
      if rec.date_responded < rec.received_date
        rec.errors.add(:date_responded, "can't be before date received")
      elsif rec.date_responded > Date.today
        rec.errors.add(:date_responded, "can't be in the future")
      end
    end
  end


  def validate_outcome(rec)
    if rec.info_held_status&.held? || rec.info_held_status&.part_held?
      rec.errors.add(:outcome, "can't be blank") if rec.outcome.blank?
    else
      rec.errors.add(:outcome, 'can only be present if information held or part held') if rec.outcome.present?
    end
  end

  def validate_refusal_reason(rec)
    if rec.info_held_status&.not_confirmed?
      if rec.refusal_reason.blank?
        rec.errors.add(:refusal_reason, 'must be present for the specified outcome')
      end
    elsif rec.refusal_reason.present?
      rec.errors.add(:refusal_reason, "cannot be present unless Information Held in 'Other'")
    end
  end

  def validate_exemptions(rec)
    if exemption_required?(rec)
      validate_at_least_one_exemption_present(rec)
      validate_cost_exemption_not_present_for_part_refused(rec)
      validate_cost_exemption_not_present_for_ncnd(rec)
    else
      validate_exemptions_not_present(rec)
    end
  end

  def exemption_required?(rec)
    info_not_confirmed_and_refusal_ncnd?(rec) || info_held_and_refused_fully_or_in_part?(rec)
  end

  def info_not_confirmed_and_refusal_ncnd?(rec)
    rec.info_held_status&.not_confirmed? && rec.refusal_reason&.ncnd?
  end

  def info_held_and_refused_fully_or_in_part?(rec)
    info_held_or_part_held?(rec) && refused_or_part_refused?(rec)
  end

  def info_held_or_part_held?(rec)
    rec.info_held_status&.held? || rec.info_held_status&.part_held?
  end

  def refused_or_part_refused?(rec)
    rec.outcome&.fully_refused? || rec.outcome&.part_refused?
  end

  def validate_exemptions_not_present(rec)
    if rec.exemptions.any?
      rec.errors.add(:exemptions, 'cannot be present unless case was fully or partly refused, or information held not confirmed and NCND')
    end
  end

  def validate_at_least_one_exemption_present(rec)
    if rec.exemptions.empty?
      rec.errors.add(:exemptions, "must be specified for this outcome")
    end
  end

  def validate_cost_exemption_not_present_for_part_refused(rec)
    if rec.outcome&.part_refused?  && rec.exemptions.include?(CaseClosure::Exemption.s12)
      rec.errors.add(:exemptions, 'cost is not valid for part refusals')
    end
  end

  def validate_cost_exemption_not_present_for_ncnd(rec)
    if rec.info_held_status.not_confirmed? && rec.exemptions.include?(CaseClosure::Exemption.s12)
      rec.errors.add(:exemptions, 'cost is not valid NCND')
    end
  end


end
