# == Schema Information
#
# Table name: retention_schedules
#
#  id                       :bigint           not null, primary key
#  case_id                  :bigint           not null
#  planned_destruction_date :date
#  erasure_date             :date
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  state                    :string
#
FactoryBot.define do
  factory :retention_schedule do
    planned_destruction_date { "2022-04-01" }

    status { "not_set" }
  end
end
