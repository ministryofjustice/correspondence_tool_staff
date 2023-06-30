FactoryBot.define do
  factory :retention_schedule do
    planned_destruction_date { "2022-04-01" }

    status { "not_set" }
  end
end
