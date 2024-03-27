# == Schema Information
#
# Table name: cases
#
#  id                       :integer          not null, primary key
#  name                     :string
#  email                    :string
#  message                  :text
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  received_date            :date
#  postal_address           :string
#  subject                  :string
#  properties               :jsonb
#  requester_type           :enum
#  number                   :string           not null
#  date_responded           :date
#  outcome_id               :integer
#  refusal_reason_id        :integer
#  current_state            :string
#  last_transitioned_at     :datetime
#  delivery_method          :enum
#  workflow                 :string
#  deleted                  :boolean          default(FALSE)
#  info_held_status_id      :integer
#  type                     :string
#  appeal_outcome_id        :integer
#  dirty                    :boolean          default(FALSE)
#  reason_for_deletion      :string
#  user_id                  :integer          default(-100), not null
#  reason_for_lateness_id   :bigint
#  reason_for_lateness_note :string
#

class Case::OverturnedICO::SAR < Case::OverturnedICO::Base
  include DraftTimeliness::ProgressedForClearance

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

  attr_accessor :missing_info

  def correspondence_type_for_business_unit_assignment
    CorrespondenceType.sar
  end

  def self.state_machine_name
    "sar"
  end

  def within_escalation_deadline?
    false
  end

  def self.type_abbreviation
    "OVERTURNED_SAR"
  end

  def validate_original_ico_appeal
    if original_ico_appeal.blank?
      errors.add(:original_ico_appeal, :blank)
    else
      unless original_ico_appeal.is_a?(Case::ICO::SAR)
        errors.add(:original_ico_appeal, :not_ico_sar)
      end
    end
  end

  def overturned_ico_sar?
    true
  end

  def respond_and_close(current_user)
    state_machine.respond!(acting_user: current_user, acting_team: responding_team)
    state_machine.close!(acting_user: current_user, acting_team: responding_team)
  end
end
