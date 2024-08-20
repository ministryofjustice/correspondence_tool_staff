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

    location { Faker::Company.name }
    data_request_area_type { "prison" }
  end
end
