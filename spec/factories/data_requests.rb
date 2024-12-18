# == Schema Information
#
# Table name: data_requests
#
#  id                      :integer          not null, primary key
#  case_id                 :integer          not null
#  user_id                 :integer          not null
#  location                :string
#  request_type            :enum             not null
#  date_requested          :date             not null
#  cached_date_received    :date
#  cached_num_pages        :integer          default(0), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  request_type_note       :text             default(""), not null
#  date_from               :date
#  date_to                 :date
#  completed               :boolean          default(FALSE), not null
#  contact_id              :bigint
#  email_branston_archives :boolean          default(FALSE)
#  data_request_area_id    :bigint
#
FactoryBot.define do
  factory :data_request do
    association :offender_sar_case
    association :user
    association :data_request_area

    request_type    { "all_prison_records" }
    date_requested  { Date.current }

    trait :other do
      request_type { "other" }
      request_type_note { "Lorem ipsum" }
    end

    trait :with_date_range do
      date_from { Date.new(2018, 0o1, 0o1) }
      date_to { Date.new(2018, 12, 31) }
    end

    trait :with_date_from do
      date_from { Date.new(2018, 0o1, 0o1) }
    end

    trait :with_date_to do
      date_to { Date.new(2018, 12, 31) }
    end

    trait :completed do
      completed { true }
    end
  end
end
