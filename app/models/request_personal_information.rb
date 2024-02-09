class RequestPersonalInformation
  include ActiveModel::API

  OWN_DATA = "your own".freeze
  LEGAL_REPRESENTATIVE = "legal representative".freeze

  attr_accessor :requesting_own_data,
                :subject_full_name,
                :subject_other_name,
                :subject_dob,
                :requestor_relationship,
                :requestor_name,
                :requester_organisation_name,
                :letter_of_consent_file_name,
                :photo_id_file_name,
                :proof_of_address_file_name

  def requesting_own_data?
    requesting_own_data.downcase == OWN_DATA
  end

  def request_by_legal_representative?
    !requesting_own_data? && subject_relationship.downcase == LEGAL_REPRESENTATIVE
  end
end
