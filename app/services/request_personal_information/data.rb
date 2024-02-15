class RequestPersonalInformation::Data
  def initialize(payload)
    @payload = payload
  end

  def submission_id
    @payload[:submissionId]
  end

  def answers
    @payload[:submissionAnswers]
  end

  def attachments
    @payload[:attachments].map do |attachment|
      RequestPersonalInformation::Attachment.new(attachment)
    end
  end

  def requesting_own_data
    answers[:"requesting-own-data_radios_1"]
    # Someone else's
    # Your own
  end

  def personal_data_full_name
    answers[:"request-personal-data_text_1"]
  end

  def personal_data_other_name
    answers[:"request-personal-data_text_2"]
  end

  def personal_data_dob
    answers[:"personal-dob_date_1"]
  end

  def data_subject_full_name
    answers[:"data-subject-name_text_1"]
  end

  def data_subject_other_name
    answers[:"data-subject-name_text_2"]
  end

  def data_subject_dob
    answers[:"subject-date-of-birth_date_1"]
  end

  def data_subject_relationship
    answers[:"relationship-subject_radios_1"]
    # Legal representative
    # Relative, friend or something else
  end

  def requestor_name
    answers[:"requestor-details_text_1"]
  end

  def legal_representative_organisation_name
    answers[:"solicitor-details_text_1"]
  end

  def legal_representative_name
    answers[:"solicitor-details_text_2"]
  end

  def letter_of_consent_file_name
    answers[:"letter-of-consent_multiupload_1"]
  end

  def photo_id_file_name
    answers[:"personal-file-upload_multiupload_1"]
  end

  def proof_of_address_file_name
    answers[:"personal-address-upload_multiupload_1"]
  end

  def subject_photo_id_file_name
    answers[:"subject-photo-id_multiupload_1"]
  end

  def subject_proof_of_address_file_name
    answers[:"subject-address-id_multiupload_1"]
  end

  def contact_address
    answers[:"contact-address_textarea_1"]
  end

  def contact_email
    answers[:"contact-email_email_1"]
  end

  def needed_for_court
    answers[:"is-it-needed-for-court_radios_1"]
  end

  def needed_for_court_information
    answers[:"needed-for-court_textarea_1"]
  end

  # PRISON

  def prison_service_data
    answers[:"personal-information-hmpps_radios_1"]
  end

  def currently_in_prison
    answers[:"current-prison_radios_1"]
  end

  def subject_current_prison
    answers[:"current-prison-name_text_1"]
  end

  def subject_previous_prison
    answers[:"previous-prison_text_1"]
  end

  def previous_prison
    answers[:"mine-recent-prison_text_1"]
  end

  def subject_prison_number
    answers[:"subject-prison_text_1"]
  end

  def prison_number
    answers[:"mine-prison_text_1"]
  end

  def prison_information
    answers[:"prison-service-data_checkboxes_1"]
  end

  def prison_information_other
    answers[:"prison-data-something-else_textarea_1"]
  end

  def prison_data_from
    answers[:"prison-dates_date_1"]
  end

  def prison_data_to
    answers[:"prison-dates_date_2"]
  end

  # PROBATION

  def probation_service_data
    answers[:"probation-information_radios_1"]
  end

  def probation_office
    answers[:"mine-probation_text_1"]
  end

  def subject_probation_office
    answers[:"subject-probation_text_1"]
  end

  def probation_information
    answers[:probation_checkboxes_1]
  end

  def probation_information_other
    answers[:probation_textarea_1]
  end

  def probation_data_from
    answers[:"probation-dates_date_1"]
  end

  def probation_data_to
    answers[:"probation-dates_date_2"]
  end

  # LAA

  def laa_data
    answers[:"laa-information_radios_1"]
  end

  def laa_information
    answers[:laa_textarea_1]
  end

  def laa_data_from
    answers[:"laa-dates_date_1"]
  end

  def laa_data_to
    answers[:"laa-dates_date_2"]
  end

  # OPG

  def opg_data
    answers[:"opg-information_radios_1"]
  end

  def opg_information
    answers[:opg_textarea_1]
  end

  def opg_data_from
    answers[:"opg-dates_date_1"]
  end

  def opg_data_to
    answers[:"opg-dates_date_2"]
  end

  # Other

  def other_data
    answers[:"other-information_radios_1"]
  end

  def other_information
    answers[:"what-other-information_textarea_1"]
  end

  def other_data_from
    answers[:"provide-somewhere-else-dates_date_1"]
  end

  def other_data_to
    answers[:"provide-somewhere-else-dates_date_2"]
  end

  def other_where
    answers[:"where-other-information_textarea_1"]
  end
end
