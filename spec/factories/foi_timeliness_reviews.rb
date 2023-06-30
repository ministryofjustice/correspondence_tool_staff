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
  factory :timeliness_review,
          class: "Case::FOI::TimelinessReview",
          parent: :case do
    transient do
      identifier { "foi timeliness review" }
    end
  end

  factory :accepted_timeliness_review,
          class: "Case::FOI::TimelinessReview",
          parent: :accepted_case,
          aliases: [:foi_timeliness_review_being_drafted] do
    transient do
      identifier { "accepted foi timeliness review case" }
    end
  end

  factory :closed_timeliness_review,
          class: "Case::FOI::TimelinessReview",
          parent: :closed_case do
    transient do
      identifier { "closed foi timeliness review case" }
    end
  end
end
