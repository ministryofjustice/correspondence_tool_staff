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
#

FactoryGirl.define do

  factory :case do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    association :category, factory: :category, strategy: :create
    subject { Faker::Hipster.sentence(1, word_count: 4) }
    message { Faker::Lorem.paragraph(1) }
    received_date Time.zone.today.to_s
    postal_address { Faker::Address.street_address }
    # state 'unassigned'

    factory :assigned_case do
      after(:create) do |kase, _evaluator|
        assignment = create(:assignment, case_id: kase.id)
        create(:case_transition,
               case_id: kase.id,
               to_state: 'awaiting_responder',
               user_id: assignment.assigner.id,
               assignee_id: assignment.assignee.id,
               event: 'assign_responder')
      end
    end
  end

end
