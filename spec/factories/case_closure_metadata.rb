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

    trait :s22 do
      subtype       'qualified'
      name          '(s22) - Information intended for future publication'
      abbreviation  'future'
      sequence_id   605
    end

    trait :s21 do
      subtype       'absolute'
      name          '(s21) - Information accessible by other means'
      abbreviation  'othermeans'
      sequence_id   510
    end

    factory :outcome, class: CaseClosure::Outcome do
      subtype nil
      sequence(:name) { |n| "Outcome #{n}" }
      sequence(:sequence_id) { |n| n }

      trait :requires_refusal_reason do
        requires_refusal_reason true
      end

      trait :granted do
        name 'Granted in full'
        abbreviation 'granted'
        sequence_id 10
      end

      trait :part_refused do
        name 'Refused in part'
        abbreviation 'part'
        sequence_id 20
        requires_refusal_reason true
      end

      trait :refused do
        name 'Refused fully'
        abbreviation 'refused'
        sequence_id 30
        requires_refusal_reason true
      end

      trait :clarify do
        name 'Clarification needed - Section 1(3)'
        abbreviation 'clarify'
        sequence_id 15
      end
    end

    factory :refusal_reason, class: CaseClosure::RefusalReason do
      subtype nil
      sequence(:name) { |n| "RefusalReason #{n}" }
      sequence(:sequence_id) { |n| 100 + n }

      trait :requires_exemption do
        requires_exemption true
      end

      trait :exempt do
        name                'Exemption applied'
        abbreviation        'exempt'
        sequence_id         110
        requires_exemption  true
      end

      trait :noinfo do
        name                'Information not held'
        abbreviation        'noinfo'
        sequence_id         120
        requires_exemption  false
      end

      trait :notmet do
        name                's8(1) - Conditions for submitting request not met'
        abbreviation        'notmet'
        sequence_id         130
        requires_exemption  false
      end

      trait :cost do
        name                '(s12) - Exceeded cost'
        abbreviation        'cost'
        sequence_id         140
        requires_exemption  false
      end

      trait :vex do
        name                '(s14(1)) - Vexatious'
        abbreviation        'vex'
        sequence_id         150
        requires_exemption  false
      end

      trait :repeat do
        name                '(s14(2)) - Repeated request'
        abbreviation        'repeat'
        sequence_id         160
        requires_exemption  false
      end
    end
  end


end
