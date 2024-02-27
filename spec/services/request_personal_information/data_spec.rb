require "rails_helper"

describe RequestPersonalInformation::Data do
  subject(:data) { described_class.new(payload) }

  describe "#submission_id" do
    let(:value) { "id_value" }
    let(:payload) { { submissionId: value } }

    it "gets the value from the payload" do
      expect(data.submission_id).to eq value
    end
  end

  describe "#answers" do
    let(:value) { { some: "json" } }
    let(:payload) { { submissionAnswers: value } }

    it "gets the value from the payload" do
      expect(data.answers).to eq value
    end
  end

  describe "#attachments" do
    let(:value) { { some: "json" } }
    let(:payload) { { attachments: [value] } }

    it "passes data from the payload to another object" do
      expect(RequestPersonalInformation::Attachment).to receive(:new).with(value)
      data.attachments
    end
  end

  describe "data from answers payload" do
    let(:payload) { { submissionAnswers: answers_payload } }

    mapped_values = {
      requesting_own_data: "requesting-own-data_radios_1",
      personal_data_full_name: "request-personal-data_text_1",
      personal_data_other_name: "request-personal-data_text_2",
      personal_data_dob: "personal-dob_date_1",
      data_subject_full_name: "data-subject-name_text_1",
      data_subject_other_name: "data-subject-name_text_2",
      data_subject_dob: "subject-date-of-birth_date_1",
      data_subject_relationship: "relationship-subject_radios_1",
      requestor_name: "requestor-details_text_1",
      legal_representative_organisation_name: "solicitor-details_text_1",
      legal_representative_name: "solicitor-details_text_2",
      letter_of_consent_file_name: "letter-of-consent_multiupload_1",
      photo_id_file_name: "personal-file-upload_multiupload_1",
      proof_of_address_file_name: "personal-address-upload_multiupload_1",
      subject_photo_id_file_name: "subject-photo-id_multiupload_1",
      subject_proof_of_address_file_name: "subject-address-id_multiupload_1",
      contact_address: "contact-address_textarea_1",
      contact_email: "contact-email_email_1",
      needed_for_court: "is-it-needed-for-court_radios_1",
      needed_for_court_information: "needed-for-court_textarea_1",
      prison_service_data: "personal-information-hmpps_radios_1",
      currently_in_prison: "current-prison_radios_1",
      subject_current_prison: "current-prison-name_text_1",
      subject_previous_prison: "previous-prison_text_1",
      previous_prison: "mine-recent-prison_text_1",
      subject_prison_number: "subject-prison_text_1",
      prison_number: "mine-prison_text_1",
      prison_information: "prison-service-data_checkboxes_1",
      prison_information_other: "prison-data-something-else_textarea_1",
      prison_data_from: "prison-dates_date_1",
      prison_data_to: "prison-dates_date_2",
      probation_service_data: "probation-information_radios_1",
      probation_office: "mine-probation_text_1",
      subject_probation_office: "subject-probation_text_1",
      probation_information: "probation-service-data_checkboxes_1",
      probation_information_other: "probation-data-something-else_textarea_1",
      probation_data_from: "probation-dates_date_1",
      probation_data_to: "probation-dates_date_2",
      laa_data: "laa-information_radios_1",
      laa_information: :laa_textarea_1,
      laa_data_from: "laa-dates_date_1",
      laa_data_to: "laa-dates_date_2",
      opg_data: "opg-information_radios_1",
      opg_information: :opg_textarea_1,
      opg_data_from: "opg-dates_date_1",
      opg_data_to: "opg-dates_date_2",
      other_data: "other-information_radios_1",
      other_information: "what-other-information_textarea_1",
      other_data_from: "provide-somewhere-else-dates_date_1",
      other_data_to: "provide-somewhere-else-dates_date_2",
      other_where: "where-other-information_textarea_1",
    }

    mapped_values.each do |method, payload_key|
      let(:value) { "data_value" }

      describe "##{method}" do
        let(:answers_payload) { Hash[payload_key.to_sym, value] }

        it "gets the value from the answers payload" do
          expect(data.send(method)).to eq value
        end
      end
    end
  end
end
