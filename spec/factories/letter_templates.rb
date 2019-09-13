FactoryBot.define do
  factory :letter_template do
    sequence(:name) { |n| "Letter to requester #{n}" }

    body { "Thank you for your offender subject access request, <%= values.name %>" }
    template_type { 'acknowledgement' }
  end
end
