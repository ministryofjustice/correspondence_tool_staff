class FoiComplianceReview < Case

<<<<<<< HEAD
=======
  belongs_to :appeal_outcome, class_name: 'CaseClosure::AppealOutcome'

  def check_is_flagged
    unless current_state.in?([nil, 'unassigned'])
      errors.add(:base, 'Internal reviews must be flagged for clearance') unless flagged?
    end
  end

  def is_internal_review?
    true
  end

  def appeal_outcome_name
    appeal_outcome&.name
  end

  def appeal_outcome_name=(name)
    self.appeal_outcome = CaseClosure::AppealOutcome.by_name(name)
  end
>>>>>>> CT-1289 adds appeal outcomes to ccase closure metadata
end
