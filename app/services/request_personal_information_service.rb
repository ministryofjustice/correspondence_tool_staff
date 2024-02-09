class RequestPersonalInformationService
  def initialize(json_data)
    @json_data = json_data
    @rpi = RequestPersonalInformation.new
  end

  def build
    whose_data
  end

  def whose_data
    rpi.requesting_own_data = requesting_own_data
    if rpi.requesting_own_data?
      rpi.subject_full_name = personal_data_full_name
      rpi.subject_other_name = personal_data_other_name
      rpi.subject_dob = personal_data_dob
      rpi.photo_id_file_name = photo_id_name
      rpi.proof_of_address_file_name = proof_of_address_file_name
    else
      rpi.subject_full_name = data_subject_full_name
      rpi.subject_other_name = data_subject_other_name
      rpi.subject_dob = data_subject_dob
      rpi.requestor_relationship = data_subject_relationship
      if request_by_legal_representative?
        rpi.requester_organisation_name = legal_representative_organisation_name
        rpi.requestor_name = legal_representative_name
        rpi.letter_of_consent_file_name = letter_of_consent_file_name
      else
        rpi.requestor_name = requestor_name
        rpi.photo_id_file_name = photo_id_file_name
        rpi.proof_of_address_file_name = proof_of_address_file_name
      end
    end
  end

private

  def answers
    json_data["submissionAnswers"]
  end

  def requesting_own_data
    answers["requesting-own-data_radios_1"]
    # Someone else's
    # Your own
  end

  def personal_data_full_name
    answers["request-personal-data_text_1"]
  end

  def personal_data_other_name
    answers["request-personal-data_text_2"]
  end

  def personal_data_dob
    answers["personal-dob_date_1"]
  end

  def data_subject_full_name
    answers["data-subject-name_text_1"]
  end

  def data_subject_other_name
    answers["data-subject-name_text_2"]
  end

  def data_subject_dob
    answers["subject-date-of-birth_date_1"]
  end

  def data_subject_relationship
    answers["relationship-subject_radios_1"]
    # Legal representative
    # Relative, friend or something else
  end

  def requestor_name
    answers["requestor-details_text_1"]
  end

  def legal_representative_organisation_name
    answers["solicitor-details_text_1"]
  end

  def legal_representative_name
    answers["solicitor-details_text_2"]
  end

  def letter_of_consent_file_name
    answers["letter-of-consent_multiupload_1"]
  end

  def photo_id_file_name
    answers["personal-file-upload_multiupload_1"]
  end

  def proof_of_address_file_name
    answers["personal-address-upload_multiupload_1"]
  end
end
