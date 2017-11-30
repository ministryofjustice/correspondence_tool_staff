# == Schema Information
#
# Table name: cases
#
#  id                   :integer          not null, primary key
#  name                 :string
#  email                :string
#  message              :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  category_id          :integer
#  received_date        :date
#  postal_address       :string
#  subject              :string
#  properties           :jsonb
#  requester_type       :enum
#  number               :string           not null
#  date_responded       :date
#  outcome_id           :integer
#  refusal_reason_id    :integer
#  current_state        :string
#  last_transitioned_at :datetime
#  delivery_method      :enum
#  workflow             :string
#  deleted?             :boolean          default(FALSE)
#  info_held_status_id  :integer
#  type                 :string           default("Case")
#  appeal_outcome_id    :integer
#

class Case::FOI::InternalReview < Case

  belongs_to :appeal_outcome, class_name: CaseClosure::AppealOutcome

  def appeal_outcome_name=(name)
    self.appeal_outcome = CaseClosure::AppealOutcome.by_name(name)
  end

  def appeal_outcome_name
    appeal_outcome&.name
  end
end
