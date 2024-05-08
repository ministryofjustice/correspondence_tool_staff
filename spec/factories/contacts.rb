# == Schema Information
#
# Table name: contacts
#
#  id                  :bigint           not null, primary key
#  name                :string
#  address_line_1      :string
#  address_line_2      :string
#  town                :string
#  county              :string
#  postcode            :string
#  data_request_emails :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  contact_type_id     :bigint
#  data_request_name   :string
#  escalation_name     :string
#  escalation_emails   :string
#
FactoryBot.define do
  factory :contact do
    name { "HMP halifax" }
    address_line_1 { "123 test road" }
    address_line_2 {}
    town {}
    county {}
    postcode { "FE2 9JK" }
    contact_type { create(:category_reference) }

    factory :prison do
      contact_type { create(:category_reference, code: "prison") }
      escalation_name { "Governor" }
      escalation_emails { "governor@prison.com" }
    end
  end
end
