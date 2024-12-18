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
  def self.decorator_class
    Case::ICO::SARDecorator
  end

  def original_case_type = "SAR"

  def has_overturn?
    linked_cases.pluck(:type).include?("Case::OverturnedICO::SAR")
  end

  def reset_responding_assignment_flag
    responder_assignment.update(state: "pending")
  end

  SAR_COMPLAINT_OUTCOMES = {
    "bau_ico_informed" => "Was originally treated as BAU, the ICO have been informed",
    "bau_and_now_responded_as_sar" => "Was originally treated as BAU and we have now also responded as a SAR",
    "not_received_now_responded_as_sar" => "No evidence of ever receiving the SAR. We have now responded to the SAR",
    "sar_processed_but_overdue" => "SAR Timeliness breach - SAR processed correctly but is overdue",
    "sar_incorrectly_processed_now_responded_as_sar" => "SAR Timeliness breach - SAR was not processed correctly (e.g. logged as a SAR). We have now provided a SAR response",
    "responded_to_sar_and_ico_informed" => "We have already responded to the SAR, the ICO were informed",
    "revised_sar_sent-exemptions_issue" => "Revised SAR response sent, as correct exemption(s) was not applied originally by the business area",
    "revised_sar_sent-undisclosed_information" => "Revised SAR response sent, as some information should have been disclosed by the business area",
    "other_outcome" => "Other (state why in notes section)",
  }.freeze

  jsonb_accessor :properties,
                 sar_complaint_outcomes: [:string]
end
