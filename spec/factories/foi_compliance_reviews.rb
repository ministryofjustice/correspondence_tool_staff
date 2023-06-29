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
#  deleted              :boolean          default(FALSE)
#  info_held_status_id  :integer
#  type                 :string
#  appeal_outcome_id    :integer
#

FactoryBot.define do
  factory :compliance_review,
          class: "Case::FOI::ComplianceReview",
          parent: :case do
    identifier { "foi compliance review case" }
  end

  factory :accepted_compliance_review,
          class: "Case::FOI::ComplianceReview",
          parent: :accepted_case,
          aliases: [:compliance_review_case_being_drafted] do
    identifier { "accepted foi compliance review case" }
  end

  factory :awaiting_responder_compliance_review,
          class: "Case::FOI::ComplianceReview",
          parent: :awaiting_responder_case,
          aliases: [:assigned_compliance_review_case] do
    identifier { "awaiting responder foi compliance review case" }
  end

  factory :compliance_review_with_response,
          class: "Case::FOI::ComplianceReview",
          parent: :case_with_response do
    transient do
      identifier { "foi compliance review case with response" }
    end
  end

  factory :responded_compliance_review,
          class: "Case::FOI::ComplianceReview",
          parent: :responded_case do
    transient do
      identifier { "responded foi compliance review case" }
    end
  end

  factory :closed_compliance_review,
          class: "Case::FOI::ComplianceReview",
          parent: :closed_case do
    transient do
      identifier { "closed foi compliance review case" }
    end
  end
end
