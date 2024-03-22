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
class PersonalInformationRequest < ApplicationRecord
  include Rails.application.routes.url_helpers

  OWN_DATA = "your own".freeze
  LEGAL_REPRESENTATIVE = "legal representative".freeze
  YES = "yes".freeze
  BRANSTON = :branston
  DISCLOSURE = :disclosure

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

  default_scope { where(deleted: false) }

  def self.build(payload)
    data = RequestPersonalInformation::Data.new(payload)
    rpi = PersonalInformationRequest.new

    rpi.build_with(data)

    rpi
  end

  def self.valid_target?(target)
    [BRANSTON, DISCLOSURE].include?(target.to_sym)
  end

  def self.email_for_target(target)
    case target
    when BRANSTON
      Settings.emails.branston
    when DISCLOSURE
      Settings.emails.disclosure
    end
  end

  def targets
    result = []
    if prison_service_data? || probation_service_data?
      result << BRANSTON
    end

    if laa_data? || opg_data? || other_data?
      result << DISCLOSURE
    end

    result
  end

  def build_with(data)
    request_builder.build(data) # This needs to be build first
    file_builder.build(data)
  end

  def requesting_own_data?
    requesting_own_data.downcase == OWN_DATA
  end

  def request_by_legal_representative?
    !requesting_own_data? && requestor_relationship.downcase == LEGAL_REPRESENTATIVE
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

  def attachment_url(target)
    rpi_file_download_url(target, submission_id)
  end

  def temporary_url(target)
    CASE_UPLOADS_S3_BUCKET.object(key(target)).presigned_url(:get, expires_in: Settings.attachments_presigned_url_expiry)
  end

  def to_markdown(target)
    raise ArgumentError, "Unknown target: ${target}" unless self.class.valid_target?(target)

    raw_template = File.read("app/views/request_personal_information/#{target}.text.erb")
    stripped_whitespace_template = raw_template.lines.map(&:strip).join("\n")
    erb_template = ERB.new(stripped_whitespace_template)
    erb_template.result(binding)
  end

  def key(target)
    "rpi/#{target}/#{submission_id}.zip"
  end

private

  def request_builder
    @request_builder ||= RequestPersonalInformation::RequestBuilder.new(self)
  end

  def file_builder
    @file_builder ||= RequestPersonalInformation::FileBuilder.new(self, targets)
  end
end
