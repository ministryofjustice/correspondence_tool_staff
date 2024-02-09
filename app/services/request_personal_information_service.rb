class RequestPersonalInformationService
  def initialize(json_data)
    @json_data = json_data
    @rpi = RequestPersonalInformation.new
  end

  def build
    build_who
    build_where
  end

  def build_who
    rpi.requesting_own_data = requesting_own_data
    if rpi.requesting_own_data?
      build_own_data
    else
      build_someone_else_data
    end

    rpi.contact_address = contact_address
    rpi.contact_email = contact_email
    rpi.needed_for_court = needed_for_court
    if rpi.needed_for_court?
      rpi.needed_for_court_information = needed_for_court_information
    end
  end

  def build_own_data
    rpi.subject_full_name = personal_data_full_name
    rpi.subject_other_name = personal_data_other_name
    rpi.subject_dob = personal_data_dob
    rpi.photo_id_file_name = photo_id_name
    rpi.proof_of_address_file_name = proof_of_address_file_name
    rpi.subject_photo_id_file_name = photo_id_file_name
    rpi.subject_proof_of_address_file_name = proof_of_address_file_name
  end

  def build_someone_else_data
    rpi.subject_full_name = data_subject_full_name
    rpi.subject_other_name = data_subject_other_name
    rpi.subject_dob = data_subject_dob
    rpi.requestor_relationship = data_subject_relationship
    if request_by_legal_representative?
      rpi.requester_organisation_name = legal_representative_organisation_name
      rpi.requestor_name = legal_representative_name
    else
      rpi.requestor_name = requestor_name
      rpi.requestor_photo_id_file_name = photo_id_file_name
      rpi.requestor_proof_of_address_file_name = proof_of_address_file_name
      rpi.subject_photo_id_file_name = subject_photo_id_file_name
      rpi.subject_proof_of_address_file_name = subject_proof_of_address_file_name
    end
    rpi.letter_of_consent_file_name = letter_of_consent_file_name
  end

  def build_where
    rpi.prison_service_data = prison_service_data
    rpi.probation_service_data = probation_service_data
    rpi.laa_data = laa_data
    rpi.opg_data = opg_data
    rpi.other_data = other_data
    build_prison_data if rpi.prison_service_data?
    build_probation_data if rpi.probation_service_data?
    build_laa_data if rpi.laa_data?
    build_opg_data if rpi.opg_data?
  end

  def build_prison_data
    if rpi.requesting_own_data?
      rpi.currently_in_prison = currently_in_prison
      rpi.subject_prison_number = subject_prison_number
      rpi.previous_prison = previous_prison
    else
      rpi.subject_prison_number = prison_number
      if rpi.currently_in_prison?
        rpi.current_prison = subject_current_prison
      else
        rpi.previous_prison = subject_previous_prison
      end
    end

    rpi.prison_information = prison_information
    rpi.prison_information_other = prison_information_other
    rpi.prison_data_from = prison_data_from
    rpi.prison_data_to = prison_data_to
  end

  def build_probation_data
    if rpi.requesting_own_data? # rubocop:disable Style/ConditionalAssignment
      rpi.probation_office = probation_office
    else
      rpi.probation_office = subject_probation_office
    end

    rpi.probation_information = probation_information
    rpi.probation_information_other = probation_information_other
    rpi.probation_data_from = probation_data_from
    rpi.probation_data_to = probation_data_to
  end

  def build_laa_data
    rpi.laa_information = laa_information
    rpi.laa_data_from = laa_data_from
    rpi.laa_data_to = laa_data_to
  end

  def build_opg_data
    rpi.opg_information = opg_information
    rpi.opg_data_from = opg_data_from
    rpi.opg_data_to = opg_data_to
  end

  def build_other_data
    rpi.other_information = other_information
    rpi.other_data_from = other_data_from
    rpi.other_data_to = other_data_to
    rpi.other_where = other_where
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

  def subject_photo_id_file_name
    answers["subject-photo-id_multiupload_1"]
  end

  def subject_proof_of_address_file_name
    answers["subject-address-id_multiupload_1]"]
  end

  def contact_address
    answers["contact-address_textarea_1"]
  end

  def contact_email
    answers["contact-email_email_1"]
  end

  def needed_for_court
    answers["is-it-needed-for-court_radios_1"]
  end

  def needed_for_court_information
    answers["needed-for-court_textarea_1"]
  end

  # PRISON

  def prison_service_data
    answers["personal-information-hmpps_radios_1"]
  end

  def currently_in_prison
    answers["current-prison_radios_1"]
  end

  def subject_current_prison
    answers["current-prison-name_text_1"]
  end

  def subject_previous_prison
    answers["previous-prison_text_1"]
  end

  def previous_prison
    answers["mine-recent-prison_text_1"]
  end

  def subject_prison_number
    answers["subject-prison_text_1"]
  end

  def prison_number
    answers["mine-prison_text_1"]
  end

  def prison_information
    answers["prison-service-data_checkboxes_1"]
  end

  def prison_information_other
    answers["prison-data-something-else_textarea_1"]
  end

  def prison_data_from
    answers["prison-dates_date_1"]
  end

  def prison_data_to
    answers["prison-dates_date_2"]
  end

  # PROBATION

  def probation_service_data
    answers["probation-information_radios_1"]
  end

  def probation_office
    answers["mine-probation_text_1"]
  end

  def subject_probation_office
    answers["subject-probation_text_1"]
  end

  def probation_information
    answers["probation_checkboxes_1"]
  end

  def probation_information_other
    answers["probation_textarea_1"]
  end

  def probation_data_from
    answers["probation-dates_date_1"]
  end

  def probation_data_to
    answers["probation-dates_date_2"]
  end

  # LAA

  def laa_data
    answers["laa-information_radios_1"]
  end

  def laa_information
    answers["laa_textarea_1"]
  end

  def laa_data_from
    answers["laa-dates_date_1"]
  end

  def laa_data_to
    answers["laa-dates_date_2"]
  end

  # OPG

  def opg_data
    answers["opg-information_radios_1"]
  end

  def opg_information
    answers["opg_textarea_1"]
  end

  def opg_data_from
    answers["opg-dates_date_1"]
  end

  def opg_data_to
    answers["opg-dates_date_2"]
  end

  # Other

  def other_data
    answers["other-information_radios_1"]
  end

  def other_information
    answers["what-other-information_textarea_1"]
  end

  def other_data_from
    answers["provide-somewhere-else-dates_date_1"]
  end

  def other_data_to
    answers["provide-somewhere-else-dates_date_2"]
  end

  def other_where
    answers["where-other-information_textarea_1"]
  end
end
