# == Schema Information
#
# Table name: cases_outcome_reasons
#
#  id                :bigint           not null, primary key
#  case_id           :bigint
#  outcome_reason_id :bigint
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class CaseOutcomeReason < ApplicationRecord
  self.table_name = :cases_outcome_reasons

  belongs_to :case,
             class_name: "Case::Base"

  belongs_to :outcome_reason,
             class_name: "CaseClosure::OutcomeReason"
end
