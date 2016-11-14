FactoryGirl.define do
  factory :category do

    name "Freedom of information request"
    abbreviation "FOI"
    escalation_time_limit 6
    internal_time_limit 10
    external_time_limit 20

    trait :foi

    trait :gq do
      name "General enquiry"
      abbreviation "GQ"
      escalation_time_limit 0
      external_time_limit 15
    end

    initialize_with { Category.find_or_create_by(name: name) }
  end
end
