# == Schema Information
#
# Table name: case_closure_metadata
#
#  id                      :integer          not null, primary key
#  type                    :string
#  subtype                 :string
#  name                    :string
#  abbreviation            :string
#  sequence_id             :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  requires_refusal_reason :boolean          default(FALSE)
#  requires_exemption      :boolean          default(FALSE)
#

FactoryGirl.define do
  factory :exemption, class: CaseClosure::Exemption do
    sequence(:subtype) { |n| "subtype_#{n}" }
    sequence(:name) { |n| "Exemption #{n}" }
    sequence(:abbreviation) { |n| "abbrev-#{n}" }
    sequence(:sequence_id) { |n| 500 + n }
    requires_refusal_reason false

    trait :ncnd do
      subtype 'ncnd'
      sequence(:name) { |n| "NCND exemption #{n}" }
    end

    trait :absolute do
      subtype 'absolute'
      sequence(:name) { |n| "Absolute exemption #{n}" }
    end

    trait :qualified do
      subtype 'qualified'
      sequence(:name) { |n| "Qualified exemption #{n}" }
    end

    factory :outcome, class: CaseClosure::Outcome do
      subtype nil
      sequence(:name) { |n| "Outcome #{n}" }
      sequence(:sequence_id) { |n| n }

      trait :requires_refusal_reason do
        requires_refusal_reason true
      end
    end

    factory :refusal_reason, class: CaseClosure::RefusalReason do
      subtype nil
      sequence(:name) { |n| "RefusalReason #{n}" }
      sequence(:sequence_id) { |n| 100 + n }

      trait :requires_exemption do
        requires_exemption true
      end
    end
  end


end
