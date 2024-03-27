# == Schema Information
#
# Table name: personal_information_requests
#
#  id               :bigint           not null, primary key
#  submission_id    :string
#  last_accessed_by :integer
#  last_accessed_at :datetime
#  deleted          :boolean          default(FALSE)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
FactoryBot.define do
  factory :personal_information_request do
    submission_id { "0fc67a0a-1c58-48ee-baec-36f9f2aaebe3" }
    requesting_own_data { "Your own" }
    subject_full_name { "Marcus Cicero" }
    subject_dob { "1944-03-15" }
    subject_photo_id_file_name { "photo_id.png" }
    subject_proof_of_address_file_name { "address.png" }
    prison_service_data { "No" }
    probation_service_data { "No" }
    laa_data { "No" }
    opg_data { "No" }
    other_data { "No" }
    contact_address { "Rome" }
    needed_for_court { "No" }

    trait :request_someone_else do
      requesting_own_data { "Someone else's" }
    end

    trait :request_as_friend do
      request_someone_else
      requestor_relationship { "Relative, friend or something else" }
    end

    trait :request_as_legal_representative do
      request_someone_else
      requestor_relationship { "Legal representative" }
    end

    trait :with_prison_service_data do
      prison_service_data { "Yes" }
    end

    trait :with_probation_service_data do
      probation_service_data { "Yes" }
    end

    trait :with_laa_data do
      laa_data { "Yes" }
    end

    trait :with_opg_data do
      opg_data { "Yes" }
    end

    trait :with_other_data do
      other_data { "Yes" }
    end

    trait :needed_for_court do
      needed_for_court { "Yes" }
    end
  end
end
