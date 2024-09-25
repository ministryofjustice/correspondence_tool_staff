# == Schema Information
#
# Table name: data_request_emails
#
#  id                   :bigint           not null, primary key
#  data_request_id      :bigint
#  email_type           :integer          default("commissioning_email")
#  email_address        :string
#  notify_id            :string
#  status               :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  data_request_area_id :bigint
#
FactoryBot.define do
  factory :data_request_email do
    association :data_request_area
    email_address { "test@user.com" }
  end

  trait :sent_to_notify do
    notify_id { "35daaa7a-2859-4c39-a5f2-bfdb17a053f4" }
  end
end
