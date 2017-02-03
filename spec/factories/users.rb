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
#

FactoryGirl.define do
  factory :user do
    email { Faker::Internet.email }
    password '12345678'
    roles %w[assigner drafter]

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
