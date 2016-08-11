FactoryGirl.define do
  factory :category do
    name "freedom_of_information_request"
    abbreviation "FOI"
    internal_time_limit 10
    external_time_limit 20
    initialize_with { Category.find_or_create_by(name: name) }
  end
end
