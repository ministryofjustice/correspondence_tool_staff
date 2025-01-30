# == Schema Information
#
# Table name: data_request_areas
#
#  id                     :bigint           not null, primary key
#  case_id                :bigint           not null
#  user_id                :bigint           not null
#  contact_id             :bigint
#  data_request_area_type :enum             not null
#  location               :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
FactoryBot.define do
  factory :data_request_area do
    association :offender_sar_case
    association :user
    association :contact

    data_request_area_type { "prison" }

    trait :in_progress do
      data_requests { [association(:data_request)] }
    end

    trait :completed do
      data_requests { [association(:data_request, :completed)] }
    end
  end
end
