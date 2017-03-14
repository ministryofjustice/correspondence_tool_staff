# == Schema Information
#
# Table name: cases
#
#  id                :integer          not null, primary key
#  name              :string
#  email             :string
#  message           :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  category_id       :integer
#  received_date     :date
#  postal_address    :string
#  subject           :string
#  properties        :jsonb
#  requester_type    :enum
#  number            :string           not null
#  date_responded    :date
#  outcome_id        :integer
#  refusal_reason_id :integer
#

FactoryGirl.define do

  factory :case do
    requester_type 'member_of_the_public'
    name { Faker::Name.name }
    email { Faker::Internet.email }
    association :category, factory: :category, strategy: :create
    subject { Faker::Hipster.sentence(1, word_count: 4).truncate(80) }
    message { Faker::Lorem.paragraph(1) }
    received_date Time.zone.today.to_s
    postal_address { Faker::Address.street_address }

    factory :assigned_case do
      transient do
        assigner { create(:assigner) }
        drafter  { create(:drafter)  }
      end

      after(:create) do |kase, evaluator|
        assignment = create :drafter_assignment,
                            case: kase,
                            assigner: evaluator.assigner,
                            assignee: evaluator.drafter
        create :case_transition_assign_responder,
               case_id: kase.id,
               user_id: assignment.assigner.id,
               assignee_id: assignment.assignee.id
      end
    end

    factory :accepted_case, parent: :assigned_case do
      after(:create) do |kase, evaluator|
        create :case_transition_accept_responder_assignment,
               case_id: kase.id,
               user_id: evaluator.assigner.id,
               assignee_id: evaluator.drafter.id,
               most_recent: true
      end
    end

    factory :case_with_response, parent: :accepted_case do
      transient do
        responses { [build(:correspondence_response, type: 'response')] }
      end

      after(:create) do |kase, evaluator|
        kase.attachments.push(*evaluator.responses)

        create :case_transition_add_responses,
               case_id: kase.id
               # filenames: [evaluator.attachment.filename]
      end
    end

    factory :responded_case, parent: :case_with_response do

      date_responded Date.today

      after(:create) do |kase, _evaluator|
        assignment = Assignment.find_by(case_id: kase.id)

        create(:case_transition_respond,
               case_id: kase.id,
               user_id: assignment.assignee.id,
               assignee_id: assignment.assignee.id)
      end
    end

    factory :closed_case, parent: :responded_case do
      date_responded 1.day.ago
      outcome { create :outcome }

      after(:create) do |kase, _evaluator|
        assignment = Assignment.find_by(case_id: kase.id)

        create(:case_transition, :close,
               case_id: kase.id,
               user_id: assignment.assignee.id,
               assignee_id: assignment.assignee.id)
      end

      trait :requires_exemption do
        outcome { create :outcome, :requires_refusal_reason }
        refusal_reason { create(:refusal_reason, :requires_exemption) }
      end

      trait :without_exemption do
        outcome { create :outcome, :requires_refusal_reason }
        refusal_reason { create(:refusal_reason) }
      end

      trait :with_ncnd_exemption do
        outcome { create :outcome, :requires_refusal_reason }
        refusal_reason { create(:refusal_reason, :requires_exemption) }
        exemptions { [create(:exemption, :ncnd)] }
      end

      trait :without_ncnd_exemption do
        outcome { create :outcome, :requires_refusal_reason }
        refusal_reason { create(:refusal_reason, :requires_exemption) }
        exemptions { [create(:exemption), create(:exemption)] }
      end

      trait :late do
        received_date 30.business_days.ago
        date_responded 1.business_day.ago
      end
    end
  end

end
