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

class Case::OverturnedICO::FOI < Case::OverturnedICO::Base
  include DraftTimeliness::ResponseAdded

  attr_accessor :flag_for_disclosure_specialists

  delegate :message, to: :original_case

  has_paper_trail only: %i[
    ico_reference
    escalation_deadline
    external_deadline
    internal_deadline
    reply_method
    email
    post_address
    original_ico_appeal
    original_case
    date_received
  ]

  def correspondence_type_for_business_unit_assignment
    CorrespondenceType.foi
  end

  def overturned_ico_foi?
    true
  end

  def all_holidays?
    true
  end

  def self.state_machine_name
    "foi"
  end

  def self.type_abbreviation
    "OVERTURNED_FOI"
  end

  def validate_original_ico_appeal
    if original_ico_appeal.blank?
      errors.add(:original_ico_appeal, :blank)
    else
      unless original_ico_appeal.is_a?(Case::ICO::FOI)
        errors.add(:original_ico_appeal, :not_ico_foi)
      end
    end
  end

private

  def set_deadlines
    self.internal_deadline = @deadline_calculator.days_before(20, external_deadline)
    self.escalation_deadline = created_at.to_date
  end
end
