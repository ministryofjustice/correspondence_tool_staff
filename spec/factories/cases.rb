# == Schema Information
#
# Table name: cases
#
#  id             :integer          not null, primary key
#  name           :string
#  email          :string
#  message        :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  category_id    :integer
#  received_date  :date
#  postal_address :string
#  subject        :string
#  properties     :jsonb
#  number         :string           not null
#  requester_type :enum
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
        response { build(:correspondence_response, type: 'response') }
      end

      after(:create) do |kase, evaluator|
        kase.attachments << evaluator.response

        create :case_transition_add_responses,
               case_id: kase.id
               # filenames: [evaluator.attachment.filename]
      end
    end

    factory :responded_case, parent: :case_with_response do
      after(:create) do |kase, _evaluator|
        assignment = Assignment.find_by(case_id: kase.id)

        create(:case_transition_respond,
               case_id: kase.id,
               user_id: assignment.assignee.id,
               assignee_id: assignment.assignee.id)
      end
    end
  end
end
