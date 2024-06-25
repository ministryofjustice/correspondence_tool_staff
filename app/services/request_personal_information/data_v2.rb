class RequestPersonalInformation::DataV2
  def initialize(payload)
    @payload = payload
  end

  def submission_id
    @payload[:submission_id]
  end

  def answers
    @payload[:answers]
  end

  def attachments
    @payload[:attachments].map do |attachment|
      RequestPersonalInformation::Attachment.new(attachment)
    end
  end

  def requesting_own_data
    answers[:subject]
    # Someone else's
    # Your own
  end

  def personal_data_full_name
    answers[:full_name]
  end

  def personal_data_other_name
    answers[:other_names]
  end

  def personal_data_dob
    answers[:date_of_birth]
  end

  def data_subject_full_name
    answers[:full_name]
  end

  def data_subject_other_name
    answers[:other_names]
  end

  def data_subject_dob
    answers[:date_of_birth]
  end

  def data_subject_relationship
    answers[:relationship]
    # Legal representative
    # Relative, friend or something else
  end

  def requestor_name
    answers[:requester_name]
  end

  def legal_representative_organisation_name
    answers[:organisation_name]
  end

  def legal_representative_name
    answers[:requester_name]
  end

  def letter_of_consent_file_name
    answers[:letter_of_consent_file_name]
  end

  def photo_id_file_name
    answers[:requester_photo_file_name] || answers[:subject_photo_file_name]
  end

  def proof_of_address_file_name
    answers[:requester_proof_of_address_file_name] || answers[:subject_proof_of_address_file_name]
  end

  def subject_photo_id_file_name
    answers[:subject_photo_file_name]
  end

  def subject_proof_of_address_file_name
    answers[:subject_proof_of_address_file_name]
  end

  def contact_address
    answers[:contact_address]
  end

  def contact_email
    answers[:contact_email]
  end

  def needed_for_court
    answers[:upcoming_court_case]
  end

  def needed_for_court_information
    answers[:upcoming_court_case_text]
  end

  # PRISON

  def prison_service_data
    answers[:prison_service]
  end

  def currently_in_prison
    answers[:currently_in_prison]
  end

  def subject_current_prison
    answers[:current_prison_name]
  end

  def subject_previous_prison
    answers[:recent_prison_name]
  end

  def previous_prison
    answers[:recent_prison_name]
  end

  def subject_prison_number
    answers[:prison_number]
  end

  def prison_number
    answers[:prison_number]
  end

  def prison_information
    answers[:prison_information]
  end

  def prison_information_other
    answers[:prison_other_data_text]
  end

  def prison_data_from
    answers[:prison_date_from]
  end

  def prison_data_to
    answers[:prison_date_to]
  end

  # PROBATION

  def probation_service_data
    answers[:probation_service]
  end

  def probation_office
    answers[:probation_office]
  end

  def subject_probation_office
    answers[:probation_office]
  end

  def probation_information
    answers[:probation_information]
  end

  def probation_information_other
    answers[:probation_other_data_text]
  end

  def probation_data_from
    answers[:probation_date_from]
  end

  def probation_data_to
    answers[:probation_date_to]
  end

  # LAA

  def laa_data
    answers[:laa]
  end

  def laa_information
    answers[:laa_text]
  end

  def laa_data_from
    answers[:laa_date_from]
  end

  def laa_data_to
    answers[:laa_date_to]
  end

  # OPG

  def opg_data
    answers[:opg]
  end

  def opg_information
    answers[:opg_text]
  end

  def opg_data_from
    answers[:opg_date_from]
  end

  def opg_data_to
    answers[:opg_date_to]
  end

  # Other

  def other_data
    answers[:moj_other]
  end

  def other_information
    answers[:moj_other_text]
  end

  def other_data_from
    answers[:moj_other_date_from]
  end

  def other_data_to
    answers[:moj_other_date_to]
  end

  def other_where
    answers[:moj_other_where]
  end
end
