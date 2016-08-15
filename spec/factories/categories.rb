FactoryGirl.define do
  factory :category do

    name "freedom_of_information_request"
    abbreviation "foi"
    internal_time_limit 9
    external_time_limit 19

    trait :gq do
      name "general_enquiry"
      abbreviation "gq"
      external_time_limit 14
    end

    initialize_with { Category.find_or_create_by(name: name) }
  end
end
