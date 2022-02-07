class CaseOutcomeReason < ApplicationRecord

  self.table_name = :cases_outcome_reasons

  belongs_to :case,
             foreign_key: :case_id,
             class_name: 'Case::Base'

  belongs_to :outcome_reason,
             class_name: 'CaseClosure::OutcomeReason',
             foreign_key: :outcome_reason_id

end
