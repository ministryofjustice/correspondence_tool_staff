class ClosedCaseValidator < ActiveModel::Validator
  # Validations applicable to cases that are closed.
  CLOSED_VALIDATIONS = {
    'SAR'=> [:validate_date_responded],
    'FOI'=> [:validate_date_responded,
             :validate_info_held_status,
             :validate_outcome,
             :validate_refusal_reason,
             :validate_exemptions],
    'ICO'=> [:validate_ico_decision,
             :validate_date_ico_decision_received,
             :validate_files_or_comment]
  }
  # Validations applicable to cases that are being processed for closure.
  #
  # e.g. missing_info is a virtual attribute which is only used when submitting
  # the form to close a case, and is only required at that time.
  PROCESSING_CLOSURE_VALIDATIONS = {
    'SAR'=> [:validate_tmm],
    'FOI'=> [],
    'ICO'=> []
  }

  class << self
    # Predicates to check what closure information is necessary for a case.
    #
    # These predicates can apply to a case or to params coming in from
    # controllers, so they outside of a ClosedCaseValidator instance which has
    # a case record to operate on.

    def outcome_required?(info_held_status:)
      case info_held_status
      when 'held'          then true
      when 'part_held'     then true
      when 'not_held'      then false
      when 'not_confirmed' then false
      end
    end

    def refusal_reason_required?(info_held_status:)
      case info_held_status
      when 'held'          then false
      when 'part_held'     then false
      when 'not_held'      then false
      when 'not_confirmed' then true
      end
    end

    def exemption_required?(info_held_status:, refusal_reason:, outcome:)
      case info_held_status
      when 'held'          then outcome.in?(%w[ refused part ])
      when 'part_held'     then outcome.in?(%w[ refused part ])
      when 'not_held'      then false
      when 'not_confirmed' then refusal_reason == 'ncnd'
      end
    end
  end




  def validate(rec)
    if closure_details_are_validatable?(rec)
      if rec.current_state == 'closed'
        run_validations(
          validations: CLOSED_VALIDATIONS[rec.type_abbreviation],
          kase: rec
        )
      elsif rec.prepared_for_close?
        run_validations(
          validations: CLOSED_VALIDATIONS[rec.type_abbreviation],
          kase: rec
        )
        run_validations(
          validations: PROCESSING_CLOSURE_VALIDATIONS[rec.type_abbreviation],
          kase: rec
        )
      end
    end
  end

  private

  def run_validations(validations:, kase:)
    validations.each do |validation|
      self.__send__(validation, kase)
    end
  end

  def validate_date_ico_decision_received(rec)
    if rec.date_ico_decision_received.blank?
      rec.errors.add(:date_ico_decision_received, "can't be blank")
    elsif rec.date_ico_decision_received > Date.today
      rec.errors.add(:date_ico_decision_received, 'future')
    elsif rec.date_ico_decision_received < 1.month.ago
      rec.errors.add(:date_ico_decision_received, 'past')
    end
  end

  def validate_ico_decision(rec)
    if rec.ico_decision.blank?
      rec.errors.add(:ico_decision, 'blank')
    elsif !rec.ico_decision.in?(%w{overturned, upheld})
      rec.errors.add(:ico_decision, 'invalid')
    end
  end

  def validate_files_or_comment(rec)
    if rec.ico_decision == 'overturned' &&
        rec.uploaded_ico_decision_files.blank? &&
        rec.ico_decision_comment.blank?
          rec.errors.add(:uploaded_ico_decision_files, 'blank')
    end
  end

  def validate_info_held_status(rec)
    if rec.info_held_status.nil?
      rec.errors.add(:info_held_status, "can't be blank")
    end
  end

  def validate_tmm(rec)
    if rec.missing_info.nil?
      rec.errors.add(:missing_info, 'must be present for the specified outcome')
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
    if self.class.outcome_required?(info_held_status: rec.info_held_status_abbreviation)
      if rec.outcome.blank?
        rec.errors.add(:outcome, "can't be blank")
      end
    elsif rec.outcome.present?
      rec.errors.add(:outcome, 'can only be present if information held or part held')
    end
  end

  def validate_refusal_reason(rec)
    if self.class.refusal_reason_required?(info_held_status: rec.info_held_status_abbreviation)
      if rec.refusal_reason.blank?
        rec.errors.add(:refusal_reason, 'must be present for the specified outcome')
      end
    elsif rec.refusal_reason.present?
      rec.errors.add(:refusal_reason, "cannot be present unless Information Held in 'Other'")
    end
  end

  def validate_exemptions(rec)
    if self.class.exemption_required?(
         info_held_status: rec.info_held_status_abbreviation,
         refusal_reason: rec.refusal_reason_abbreviation,
         outcome: rec.outcome_abbreviation,
       )
      validate_at_least_one_exemption_present(rec)
      validate_cost_exemption_not_present_for_part_refused(rec)
      validate_cost_exemption_not_present_for_ncnd(rec)
    else
      validate_exemptions_not_present(rec)
    end
  end

  def closure_details_are_validatable?(rec)
    return true if rec.ico?
    if rec.date_responded.blank?
      true
    else
      rec.date_responded > Date.new(2017, 11, 7)
    end
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
