FactoryBot.define do
  factory :letter_template do
    name { "Letter to requester" }
    body { "Thank you for your offender subject access request, <%= values.name %>" }
    type { 'acknowledgement' }
  end
end
