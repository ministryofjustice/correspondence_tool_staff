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

class Case::ICO::SAR < Case::ICO::Base
  COMPLAINT_OUTCOMES = %w[
    bau_ico_informed
    bau_and_now_responded_as_sar
    not_received_now_responded_as_sar
    sar_processed_but_overdue
    sar_incorrectly_processed_now_responded_as_sar
    responded_to_sar_and_ico_informed
    revised_sar_sent_exemptions_issue
    revised_sar_sent_undisclosed_information
    other_outcome
  ].freeze

  def self.decorator_class
    Case::ICO::SARDecorator
  end

  jsonb_accessor :properties,
                 sar_complaint_outcome: :string,
                 other_sar_complaint_outcome_note: :string

  validates :sar_complaint_outcome, presence: true, inclusion: { in: COMPLAINT_OUTCOMES }, if: -> { prepared_for_recording_outcome? }
  validates :other_sar_complaint_outcome_note, presence: true, if: -> { prepared_for_recording_outcome? && sar_complaint_outcome == "other_outcome" }

  def original_case_type = "SAR"

  def has_overturn?
    linked_cases.pluck(:type).include?("Case::OverturnedICO::SAR")
  end

  def reset_responding_assignment_flag
    responder_assignment.update(state: "pending")
  end

  def prepare_for_recording_outcome
    @preparing_for_recording_outcome = true
  end

  def prepared_for_recording_outcome?
    @preparing_for_recording_outcome == true
  end
end
