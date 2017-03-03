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
#  roles                  :string
#  full_name              :string
#

def email_from_name(name)
  email_name = name.tr(' ', '.').gsub(/\.{2,}/, '.')
  "correspondence-staff-dev+#{email_name}@digital.justice.gov.uk"
end

FactoryGirl.define do
  factory :user do
    password '12345678'
    roles %w[assigner drafter]
    sequence(:full_name) { |n| "Firstname#{n} Lastname#{n}" }
    email { Faker::Internet.email(full_name) }

    trait :dev do
      email { email_from_name(full_name) }
    end

    factory :assigner do
      roles %w[assigner]
    end

    factory :drafter do
      roles %w[drafter]
    end

    factory :approver do
      roles %w[approver]
    end
  end
end
