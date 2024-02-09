class RequestPersonalInformation
  include ActiveModel::API

  OWN_DATA = "your own".freeze
  LEGAL_REPRESENTATIVE = "legal representative".freeze
  YES = "yes".freeze

  attr_accessor :requesting_own_data,
                :subject_full_name,
                :subject_other_name,
                :subject_dob,
                :subject_photo_id_file_name,
                :subject_proof_of_address_file_name,
                :requestor_relationship,
                :requestor_name,
                :requester_organisation_name,
                :letter_of_consent_file_name,
                :requestor_photo_id_file_name,
                :requestor_proof_of_address_file_name,
                :prison_service_data,
                :currently_in_prison,
                :current_prison,
                :previous_prison,
                :subject_prison_number,
                :prison_information,
                :prison_information_other,
                :prison_data_from,
                :prison_data_to,
                :probation_service_data,
                :probation_office,
                :probation_information,
                :probation_information_other,
                :probation_data_from,
                :probation_data_to,
                :laa_data,
                :laa_information,
                :laa_data_from,
                :laa_data_to,
                :opg_data,
                :opg_information,
                :opg_data_from,
                :opg_data_to,
                :other_data,
                :other_information,
                :other_data_from,
                :other_data_to,
                :other_where,
                :contact_address,
                :contact_email,
                :needed_for_court,
                :needed_for_court_information

  def requesting_own_data?
    requesting_own_data.downcase == OWN_DATA
  end

  def request_by_legal_representative?
    !requesting_own_data? && subject_relationship.downcase == LEGAL_REPRESENTATIVE
  end

  def prison_service_data?
    prison_service_data.downcase == YES
  end

  def probation_service_data?
    probation_service_data.downcase == YES
  end

  def laa_data?
    laa_data.downcase == YES
  end

  def opg_data?
    opg_data.downcase == YES
  end

  def other_data?
    other_data.downcase == YES
  end

  def currently_in_prison?
    !requesting_own_data? && currently_in_prison.downcase == YES
  end

  def needed_for_court?
    needed_for_court.downcase == YES
  end

  def content
    <<~HERE
      # This is a test
      # # sub heading

      Are you requesting your own information or on behalf of someone else?     #{requesting_own_data}

      What is your name?    #{subject_full_name}

    HERE
  end
end
