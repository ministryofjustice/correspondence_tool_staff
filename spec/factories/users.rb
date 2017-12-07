# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  full_name              :string           not null
#  deleted_at             :datetime
#

def email_from_name(name)
  email_name = name.tr(' ', '.').gsub(/\.{2,}/, '.')
  "correspondence-staff-dev+#{email_name}@digital.justice.gov.uk"
end

FactoryGirl.define do
  sequence(:manager_name)               { |n| "Ms Manager #{n}" }
  sequence(:responder_name)             { |n| "Mr Responder #{n}" }
  sequence(:approver_name)              { |n| "Ms Approver #{n}" }
  sequence(:disclosure_specialist_name) { |n| "Disclosure Specialist #{n}" }
  sequence(:disclosure_bmt_user_name)   { |n| "Disclosure BMT #{n}" }
  sequence(:press_officer_name)         { |n| "Press Officer #{n}" }
  sequence(:private_officer_name)       { |n| "Private Officer #{n}" }
  sequence(:approver_responder_name)    { |n| "Ms Approver-Responder #{n}" }

  factory :user do
    password '12345678'
    sequence(:full_name) { |n| "Firstname#{n} Lastname#{n}" }
    email { Faker::Internet.email(full_name) }

    trait :dev do
      email { email_from_name(full_name) }
    end

    factory :manager do
      full_name      { generate(:manager_name) }
      managing_teams { [create(:managing_team)] }
    end

    factory :disclosure_bmt_user do
      full_name      { generate :disclosure_bmt_user_name }
      managing_teams { [find_or_create(:team_dacu)] }
    end

    factory :responder do
      full_name      { generate(:responder_name) }
      responding_teams { [find_or_create(:responding_team)] }
    end

    factory :approver do
      full_name      { generate(:approver_name) }
      approving_team { create(:approving_team) }
    end

    factory :approver_responder do
      full_name         { generate(:approver_responder_name) }
      approving_team    { find_or_create(:approving_team) }
      responding_teams  { [ find_or_create(:responding_team) ] }
    end

    factory :disclosure_specialist do
      full_name      { generate(:disclosure_specialist_name) }
      approving_team { find_or_create(:team_dacu_disclosure) }
    end

    factory :disclosure_specialist_bmt do
      full_name      { generate(:disclosure_specialist_name) }
      managing_teams { [find_or_create(:team_dacu)] }
      approving_team { find_or_create(:team_dacu_disclosure) }
    end

    factory :press_officer do
      full_name      { generate(:press_officer_name) }
      approving_team { find_or_create(:team_press_office) }
    end

    factory :default_press_officer do
      full_name { Settings.press_office_default_user }
      approving_team { find_or_create(:team_press_office) }
    end

    factory :private_officer do
      full_name      { generate(:private_officer_name) }
      approving_team { find_or_create(:team_private_office) }
    end

    factory :default_private_officer do
      full_name { Settings.private_office_default_user }
      approving_team { find_or_create(:team_private_office) }
    end

    factory :deactivated_user do
      full_name      { generate(:manager_name) }
      managing_teams { [create(:managing_team)] }
      deleted_at { Time.now }
    end
    factory :admin do
      full_name      { generate(:manager_name) }
      after(:create) do |user|
        user.team_roles.create role: 'admin'
      end
    end

  end
end
