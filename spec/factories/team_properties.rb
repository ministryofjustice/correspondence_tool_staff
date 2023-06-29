# == Schema Information
#
# Table name: team_properties
#
#  id         :integer          not null, primary key
#  team_id    :integer
#  key        :string
#  value      :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryBot.define do
  factory :team_property do
    team_id       { 33 }
    key           { "area" }
    value         { "Hammersmith" }

    trait :area

    trait :lead do
      key         { "lead" }
      value       { "Donald Trump" }
    end

    trait :can_allocate_foi do
      key         { "can_allocate" }
      value       { "FOI" }
    end

    trait :can_allocate_gq do
      key         { "can_allocate" }
      value       { "GQ" }
    end
  end

  sequence(:team_lead)        { |n| "Team Lead #{n}" }
  sequence(:director_general) { |n| "Director General #{n}" }
  sequence(:director)         { |n| "Director #{n}" }
  sequence(:deputy_director)  { |n| "Deputy Director #{n}" }

  factory :team_lead, class: "TeamProperty" do
    key   { "lead" }
    value { generate :team_lead }
  end

  factory :director_general, class: "TeamProperty" do
    key   { "lead" }
    value { generate :director_general }
  end

  factory :director, class: "TeamProperty" do
    key   { "lead" }
    value { generate :director }
  end

  factory :deputy_director, class: "TeamProperty" do
    key   { "lead" }
    value { generate :deputy_director }
  end
end
