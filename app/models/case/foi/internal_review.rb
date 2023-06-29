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
#  deleted              :boolean          default(FALSE)
#  info_held_status_id  :integer
#  type                 :string
#  appeal_outcome_id    :integer
#  dirty                :boolean          default(FALSE)
#

class Case::FOI::InternalReview < Case::FOI::Standard
  belongs_to :appeal_outcome, class_name: "CaseClosure::AppealOutcome"

  def check_is_flagged
    if !current_state.in?([nil, "unassigned"]) && !flagged?
      errors.add(:base, "Internal reviews must be flagged for clearance")
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

  def foi_standard?
    false
  end
end
