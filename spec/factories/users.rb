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
      managing_teams { [create(:managing_team)] }
    end

    factory :responder do
      responding_teams { [create(:responding_team)] }
    end

    factory :approver do
      approving_teams { [create(:approving_team)] }
    end

    factory :disclosure_specialist do
      approving_teams { [find_or_create(:team_dacu_disclosure)] }
    end
  end
end
