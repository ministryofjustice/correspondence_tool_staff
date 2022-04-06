FactoryBot.define do
  factory :retention_schedule do
    destruction_date { "2022-04-01" }
    references { "" }
  end
end
