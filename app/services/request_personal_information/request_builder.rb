class RequestPersonalInformation::RequestBuilder
  attr_accessor :rpi, :data

  def initialize(rpi)
    @rpi = rpi
  end

  def build(data)
    @data = data
    build_id
    build_who
    build_where
  end
end

private

def build_id
  rpi.submission_id = data.submission_id
end

def build_who
  rpi.requesting_own_data = data.requesting_own_data
  if rpi.requesting_own_data?
    build_own_data
  else
    build_someone_else_data
  end

  rpi.contact_address = data.contact_address
  rpi.contact_email = data.contact_email
  rpi.needed_for_court = data.needed_for_court
  if rpi.needed_for_court?
    rpi.needed_for_court_information = data.needed_for_court_information
  end
end

def build_own_data
  rpi.subject_full_name = data.personal_data_full_name
  rpi.subject_other_name = data.personal_data_other_name
  rpi.subject_dob = data.personal_data_dob
  rpi.subject_photo_id_file_name = data.photo_id_file_name
  rpi.subject_proof_of_address_file_name = data.proof_of_address_file_name
end

def build_someone_else_data
  rpi.subject_full_name = data.data_subject_full_name
  rpi.subject_other_name = data.data_subject_other_name
  rpi.subject_dob = data.data_subject_dob
  rpi.requestor_relationship = data.data_subject_relationship
  if rpi.request_by_legal_representative?
    rpi.requester_organisation_name = data.legal_representative_organisation_name
    rpi.requestor_name = data.legal_representative_name
  else
    rpi.requestor_name = data.requestor_name
    rpi.requestor_photo_id_file_name = data.photo_id_file_name
    rpi.requestor_proof_of_address_file_name = data.proof_of_address_file_name
    rpi.subject_photo_id_file_name = data.subject_photo_id_file_name
    rpi.subject_proof_of_address_file_name = data.subject_proof_of_address_file_name
  end
  rpi.letter_of_consent_file_name = data.letter_of_consent_file_name
end

def build_where
  rpi.prison_service_data = data.prison_service_data
  rpi.probation_service_data = data.probation_service_data
  rpi.laa_data = data.laa_data
  rpi.opg_data = data.opg_data
  rpi.other_data = data.other_data
  build_prison_data if rpi.prison_service_data?
  build_probation_data if rpi.probation_service_data?
  build_laa_data if rpi.laa_data?
  build_opg_data if rpi.opg_data?
  build_other_data if rpi.other_data?
end

def build_prison_data
  if rpi.requesting_own_data?
    rpi.subject_prison_number = data.prison_number
    rpi.previous_prison = data.previous_prison
  else
    rpi.currently_in_prison = data.currently_in_prison
    rpi.subject_prison_number = data.subject_prison_number
    if rpi.currently_in_prison?
      rpi.current_prison = data.subject_current_prison
    else
      rpi.previous_prison = data.subject_previous_prison
    end
  end

  rpi.prison_information = data.prison_information
  rpi.prison_information_other = data.prison_information_other
  rpi.prison_data_from = data.prison_data_from
  rpi.prison_data_to = data.prison_data_to
end

def build_probation_data
  if rpi.requesting_own_data? # rubocop:disable Style/ConditionalAssignment
    rpi.probation_office = data.probation_office
  else
    rpi.probation_office = data.subject_probation_office
  end

  rpi.probation_information = data.probation_information
  rpi.probation_information_other = data.probation_information_other
  rpi.probation_data_from = data.probation_data_from
  rpi.probation_data_to = data.probation_data_to
end

def build_laa_data
  rpi.laa_information = data.laa_information
  rpi.laa_data_from = data.laa_data_from
  rpi.laa_data_to = data.laa_data_to
end

def build_opg_data
  rpi.opg_information = data.opg_information
  rpi.opg_data_from = data.opg_data_from
  rpi.opg_data_to = data.opg_data_to
end

def build_other_data
  rpi.other_information = data.other_information
  rpi.other_data_from = data.other_data_from
  rpi.other_data_to = data.other_data_to
  rpi.other_where = data.other_where
end
