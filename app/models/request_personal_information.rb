class RequestPersonalInformation
  include ActiveModel::API

  OWN_DATA = "your own".freeze
  LEGAL_REPRESENTATIVE = "legal representative".freeze
  YES = "yes".freeze

  attr_accessor :submission_id,
                :requesting_own_data,
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

  def attachment_url
    @attachment_url ||= begin
      generate_pdf
      upload

      CASE_UPLOADS_S3_BUCKET.object(key).presigned_url(:get, expires_in: 1.week)
    end
  end

private

  def generate_pdf
    raw_template = File.read("app/views/request_personal_information/submission.txt.erb")
    erb_template = ERB.new(raw_template)
    # output =
    erb_template.result(binding)
    # Prawn::Document.generate("#{submission_id}.pdf") { markdown(output) }
  end

  def upload
    # uploads_object =
    CASE_UPLOADS_S3_BUCKET.object(key)
    # File.open("#{submission_id}.pdf") do |f|
    #   uploads_object.upload_file(f)
    #   File.delete(f)
    # end
  end

  def key
    "rpi/#{submission_id}"
  end
end
