class Case::FOI::InternalReview < Case

  belongs_to :appeal_outcome, class_name: CaseClosure::AppealOutcome

  def appeal_outcome_name=(name)
    self.appeal_outcome = CaseClosure::AppealOutcome.by_name(name)
  end

  def appeal_outcome_name
    appeal_outcome&.name
  end
end
