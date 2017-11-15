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
#

FactoryGirl.define do

  factory :foi_timeliness_review do
    transient do
      creation_time { 4.business_days.ago }
      identifier "new case"
      managing_team { find_or_create :team_dacu }
    end

    requester_type 'member_of_the_public'
    type 'FOITimelinessReview'
    sequence(:name) { |n| "#{identifier} name #{n}" }
    email { Faker::Internet.email(identifier) }
    # association :category, factory: :category, strategy: :create
    category
    delivery_method 'sent_by_email'
    sequence(:subject) { |n| "#{identifier} subject #{n}" }
    sequence(:message) { |n| "#{identifier} message #{n}" }
    received_date { Time.zone.today.to_s }
    sequence(:postal_address) { |n| "#{identifier} postal address #{n}" }
    created_at { creation_time }

    after(:build) do |_kase, evaluator|
      evaluator.managing_team
    end

    after(:create) do | kase, evaluator|
      ma = kase.managing_assignment
      ma.update! created_at: evaluator.creation_time
    end
  end
end
