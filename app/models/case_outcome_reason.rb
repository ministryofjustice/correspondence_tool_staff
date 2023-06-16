class CaseOutcomeReason < ApplicationRecord
  self.table_name = :cases_outcome_reasons

  belongs_to :case,
             class_name: "Case::Base"

  belongs_to :outcome_reason,
             class_name: "CaseClosure::OutcomeReason"
end
