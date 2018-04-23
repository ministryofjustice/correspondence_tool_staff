class CaseExemption < ApplicationRecord

  self.table_name = :cases_exemptions

  belongs_to :case,
             foreign_key: :case_id,
             class_name: 'Case::Base'

  belongs_to :exemption,
             class_name: 'CaseClosure::Exemption',
             foreign_key: :exemption_id

end
