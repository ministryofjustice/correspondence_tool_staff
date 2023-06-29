FactoryBot.define do
  factory :letter_template do
    sequence(:name) { |n| "Letter to requester #{n}" }
    sequence(:abbreviation) { |n| "template-#{n}" }

    body { "Thank you for your offender subject access request, <%= values.name %>" }
    letter_address { "Testing <%= values.requester_address %>" }
    template_type { "acknowledgement" }
  end

  trait :acknowledgement do
    template_type { "acknowledgement" }
  end

  trait :dispatch do
    template_type { "dispatch" }
  end
end
