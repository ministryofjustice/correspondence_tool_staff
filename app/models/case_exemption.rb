# == Schema Information
#
# Table name: cases_exemptions
#
#  id           :integer          not null, primary key
#  case_id      :integer
#  exemption_id :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class CaseExemption < ApplicationRecord

  self.table_name = :cases_exemptions

  belongs_to :case,
             class_name: 'Case::Base'

  belongs_to :exemption,
             class_name: 'CaseClosure::Exemption'

end
