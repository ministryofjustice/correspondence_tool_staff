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
#

def email_from_name(name)
  email_name = name.tr(' ', '.').gsub(/\.{2,}/, '.')
  "correspondence-staff-dev+#{email_name}@digital.justice.gov.uk"
end

FactoryGirl.define do
  factory :user do
    password '12345678'
    sequence(:full_name) { |n| "Firstname#{n} Lastname#{n}" }
    email { Faker::Internet.email(full_name) }

    trait :dev do
      email { email_from_name(full_name) }
    end

    factory :manager do
      sequence(:full_name) { |n| "Ms Manager #{n}" }
      managing_teams { [create(:managing_team)] }
    end

    factory :responder do
      sequence(:full_name) { |n| "Mr Responder #{n}" }
      responding_teams { [find_or_create(:responding_team)] }
    end

    factory :approver do
      sequence(:full_name) { |n| "Ms Approver #{n}" }
      approving_team { create(:approving_team) }
    end

    factory :disclosure_specialist do
      sequence(:full_name) { |n| "Disclosure Specialist #{n}" }
      approving_team { find_or_create(:team_dacu_disclosure) }
    end

    factory :press_officer do
      sequence(:full_name) { |n| "Press Officer #{n}" }
      approving_team { find_or_create(:team_press_office) }
    end

    factory :default_press_officer do
      full_name { Settings.press_office_default_user }
      approving_team { find_or_create(:team_press_office) }
    end

    factory :private_officer do
      sequence(:full_name) { |n| "Private Officer #{n}" }
      approving_team { find_or_create(:team_private_office) }
    end

    factory :default_private_officer do
      full_name { Settings.private_office_default_user }
      approving_team { find_or_create(:team_private_office) }
    end
  end
end
