# == Schema Information
#
# Table name: letter_templates
#
#  id                     :integer          not null, primary key
#  name                   :string
#  abbreviation           :string
#  body                   :string
#  template_type          :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  letter_address         :string           default("")
#  base_template_file_ref :string           default("ims001.docx")
#
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
