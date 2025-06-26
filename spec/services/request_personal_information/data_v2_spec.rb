require "rails_helper"

describe RequestPersonalInformation::DataV2 do
  subject(:data) { described_class.new(payload) }

  describe "#submission_id" do
    let(:value) { "id_value" }
    let(:payload) { { submission_id: value } }

    it "gets the value from the payload" do
      expect(data.submission_id).to eq value
    end
  end

  describe "#answers" do
    let(:value) { { some: "json" } }
    let(:payload) { { answers: value } }

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
    let(:payload) { { answers: answers_payload } }

    mapped_values = {
      requesting_own_data: "subject",
      personal_data_full_name: "full_name",
      personal_data_other_name: "other_names",
      personal_data_dob: "date_of_birth",
      data_subject_full_name: "full_name",
      data_subject_other_name: "other_names",
      data_subject_dob: "date_of_birth",
      data_subject_relationship: "relationship",
      requestor_name: "requester_name",
      legal_representative_organisation_name: "organisation_name",
      legal_representative_name: "requester_name",
      letter_of_consent_file_name: "letter_of_consent_file_name",
      photo_id_file_name: "requester_photo_file_name",
      proof_of_address_file_name: "requester_proof_of_address_file_name",
      subject_photo_id_file_name: "subject_photo_file_name",
      subject_proof_of_address_file_name: "subject_proof_of_address_file_name",
      contact_address: "contact_address",
      contact_email: "contact_email",
      needed_for_court: "upcoming_court_case",
      needed_for_court_information: "upcoming_court_case_text",
      prison_service_data: "prison_service",
      currently_in_prison: "currently_in_prison",
      subject_current_prison: "current_prison_name",
      subject_previous_prison: "recent_prison_name",
      previous_prison: "recent_prison_name",
      subject_prison_number: "prison_number",
      prison_number: "prison_number",
      prison_information: "prison_information",
      prison_information_other: "prison_other_data_text",
      prison_data_from: "prison_date_from",
      prison_data_to: "prison_date_to",
      probation_service_data: "probation_service",
      probation_office: "probation_office",
      subject_probation_office: "probation_office",
      probation_information: "probation_information",
      probation_information_other: "probation_other_data_text",
      probation_data_from: "probation_date_from",
      probation_data_to: "probation_date_to",
      laa_data: "laa",
      laa_information: "laa_text",
      laa_data_from: "laa_date_from",
      laa_data_to: "laa_date_to",
      opg_data: "opg",
      opg_information: "opg_text",
      opg_data_from: "opg_date_from",
      opg_data_to: "opg_date_to",
      other_data: "moj_other",
      other_information: "moj_other_text",
      other_data_from: "moj_other_date_from",
      other_data_to: "moj_other_date_to",
      other_where: "moj_other_where",
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

  describe "#photo_id_file_name" do
    context "when requester uploads are provided" do
      let(:payload) { { answers: { requester_photo_file_name: "requester.jpg", subject_photo_file_name: "subject.jpg" } } }

      it "returns requester filename" do
        expect(data.photo_id_file_name).to eq "requester.jpg"
      end
    end

    context "when only subject uploads are provided" do
      let(:payload) { { answers: { subject_photo_file_name: "subject.jpg" } } }

      it "returns subject filename" do
        expect(data.photo_id_file_name).to eq "subject.jpg"
      end
    end
  end

  describe "#proof_of_address_file_name" do
    context "when requester uploads are provided" do
      let(:payload) { { answers: { requester_proof_of_address_file_name: "requester.jpg", subject_proof_of_address_file_name: "subject.jpg" } } }

      it "returns requester filename" do
        expect(data.proof_of_address_file_name).to eq "requester.jpg"
      end
    end

    context "when only subject uploads are provided" do
      let(:payload) { { answers: { subject_proof_of_address_file_name: "subject.jpg" } } }

      it "returns subject filename" do
        expect(data.proof_of_address_file_name).to eq "subject.jpg"
      end
    end
  end
end
