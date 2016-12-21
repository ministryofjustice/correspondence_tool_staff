# == Schema Information
#
# Table name: categories
#
#  id                    :integer          not null, primary key
#  name                  :string
#  abbreviation          :string
#  internal_time_limit   :integer
#  external_time_limit   :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  escalation_time_limit :integer
#

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
