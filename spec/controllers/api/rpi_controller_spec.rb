require "rails_helper"

RSpec.describe Api::RpiController, type: :controller do
  let(:encrypted_json) { JWE.encrypt(unencrypted_json, Settings.rpi_jwe_key, alg: "dir") }

  RSpec.shared_examples "RpiController#create with valid data" do
    it "creates a job to process the payload" do
      encrypted_document = JWE.encrypt(valid_document.to_json, Settings.rpi_jwe_key, alg: "dir")
      expect(RequestPersonalInformationJob).to receive(:perform_later).with(kind_of(Integer), kind_of(Hash))
      post(:create, body: encrypted_document)
    end

    it "decrypts the body" do
      encrypted_document = JWE.encrypt(valid_document.to_json, Settings.rpi_jwe_key, alg: "dir")
      post(:create, body: encrypted_document)
      expect(assigns(:body)).to eq valid_document
    end
  end

  RSpec.shared_examples "RpiController#create with invalid data" do
    it "logs encrypted request before processing to capture errors" do
      encrypted_document = JWE.encrypt(invalid_document.to_json, Settings.rpi_jwe_key, alg: "dir")

      expect(Sentry).to receive(:capture_exception).with(kind_of(StandardError))
      post(:create, body: encrypted_document)

      expect(response.status).to eq 422

      request = PersonalInformationRequest.find_by(submission_id: submission_id)

      expect(request).not_to be_nil
      expect(request.processed).to eq false
      expect(request.log).to include("ERROR:")
    end
  end

  describe "authentication" do
    let(:invalid_json_body) do
      { invalid: "json" }.to_json
    end

    context "with no body" do
      it "responds with 401" do
        post(:create)
        expect(response.status).to eq 401
      end
    end

    context "with unencrypted data" do
      it "responds with 401" do
        post(:create, body: invalid_json_body)
        expect(response.status).to eq 401
      end
    end
  end

  describe "#create" do
    context "with invalid data" do
      let(:unencrypted_json) do
        {
          "serviceSlug": "request-personal-information-migrate",
          "submissionId": "0fc67a0a-1c58-48ee-baec-36f9f2aaebe3",
          "submissionAnswers": {
            "requesting-own-data_radios_1": "Your own",
          },
          "attachments": [],
        }.to_json
      end

      it "returns unprocessable entity" do
        post(:create, body: encrypted_json)
        expect(response.status).to eq 422
      end
    end

    context "with schema v1" do
      let(:submission_id) { SecureRandom.uuid }

      let(:valid_document) do
        {
          "schema": "1",
          "serviceSlug": "request-personal-information-migrate",
          "submissionId": submission_id,
          "submissionAnswers": {
            "requesting-own-data_radios_1": "Your own",
            "request-personal-data_text_1": "Andrew Pepler",
            "request-personal-data_text_2": "nickname",
            "personal-dob_date_1": "14 August 1978",
            "personal-file-upload_multiupload_1": "blue.jpeg",
            "personal-address-upload_multiupload_1": "address.jpeg",
            "personal-information-hmpps_radios_1": "Yes",
            "mine-prison_text_1": "answer to What was your prison number? (optional)",
            "mine-recent-prison_text_1": "answer to Which prison were you most recently in?",
            "prison-service-data_checkboxes_1": "NOMIS records; Security data; Something else",
            "prison-data-something-else_textarea_1": "ansewr to What other prison service information do you want?",
            "prison-dates_date_1": "01 January 2000",
            "prison-dates_date_2": "02 February 2000",
            "probation-information_radios_1": "Yes",
            "mine-probation_text_1": "Answer to Where is your probation office or approved premises?",
            "probation-service-data_checkboxes_1": "nDelius file; Something else",
            "probation-data-something-else_textarea_1": "answer to If you selected something else, can you provide more detail?",
            "probation-dates_date_1": "01 January 2001",
            "probation-dates_date_2": "02 February 2001",
            "laa-information_radios_1": "Yes",
            "laa_textarea_1": "answer to What information do you want from the Legal Aid Agency (LAA)?",
            "laa-dates_date_1": "01 January 2002",
            "laa-dates_date_2": "02 February 2002",
            "opg-information_radios_1": "Yes",
            "opg_textarea_1": "answer to What information do you want from the Office of the Public Guardian (OPG)?",
            "opg-dates_date_1": "01 January 2003",
            "opg-dates_date_2": "02 February 2003",
            "other-information_radios_1": "Yes",
            "what-other-information_textarea_1": "answer to What information do you want from somewhere else in the Ministry of Justice?",
            "provide-somewhere-else-dates_date_1": "01 January 2004",
            "provide-somewhere-else-dates_date_2": "02 February 2004",
            "where-other-information_textarea_1": "answer to Where in the Ministry of Justice do you think this information is held?",
            "contact-address_textarea_1": "answer to Where we'll send the information",
            "contact-email_email_1": "user@email.com",
            "is-it-needed-for-court_radios_1": "Yes",
            "needed-for-court_textarea_1": "answer to Tell us more about your upcoming court case or hearing",
          },
          "attachments": [],
        }
      end

      let(:invalid_document) do
        {
          "schema": "1",
          "submissionId": submission_id,
          "serviceSlug": "request-personal-information-migrate",
          "submissionAnswers": {
            "requesting-own-data_radios_1": "Your own",
          },
          "attachments": [],

        }
      end

      it_behaves_like "RpiController#create with valid data"
      it_behaves_like "RpiController#create with invalid data"
    end

    context "with schema v2" do
      let(:submission_id) { SecureRandom.uuid }

      let(:valid_document) do
        {
          "schema": "2",
          "submission_id": submission_id,
          "answers": {
            "subject": "Your own",
            "full_name": "Andrew Pepler",
            "other_names": "nickname",
            "date_of_birth": "14 August 1978",
            "subject_photo": "blue.jpeg",
            "subject_proof_of_address": "address.jpeg",
            "prison_service": "Yes",
            "prison_number": "answer to What was your prison number? (optional)",
            "recent_prison": "answer to Which prison were you most recently in?",
            "prison_information": "NOMIS records; Security data; Something else",
            "prison_information_text": "ansewr to What other prison service information do you want?",
            "prison_date_from": "01 January 2000",
            "prison_date_to": "02 February 2000",
            "probation_service": "Yes",
            "probation_location": "Answer to Where is your probation office or approved premises?",
            "probation_information": "nDelius file; Something else",
            "probation_information_text": "answer to If you selected something else, can you provide more detail?",
            "probation_date_from": "01 January 2001",
            "probation_date_to": "02 February 2001",
            "laa": "Yes",
            "laa_text": "answer to What information do you want from the Legal Aid Agency (LAA)?",
            "laa_date_from": "01 January 2002",
            "laa_date_to": "02 February 2002",
            "opg": "Yes",
            "opg_text": "answer to What information do you want from the Office of the Public Guardian (OPG)?",
            "opg_date_from": "01 January 2003",
            "opg_date_to": "02 February 2003",
            "moj_other": "Yes",
            "moj_other_text": "answer to What information do you want from somewhere else in the Ministry of Justice?",
            "moj_other_date_from": "01 January 2004",
            "moj_other_date_to": "02 February 2004",
            "moj_other_where": "answer to Where in the Ministry of Justice do you think this information is held?",
            "contact_address": "answer to Where we'll send the information",
            "contact_email": "user@email.com",
            "upcoming": "Yes",
            "upcoming_text": "answer to Tell us more about your upcoming court case or hearing",
            "upcoming_court_case": "The upcoming court case",
          },
          "attachments": [],
        }
      end

      let(:invalid_document) do
        {
          "schema": "2",
          "submission_id": submission_id,
          "answers": {},
        }
      end

      it_behaves_like "RpiController#create with valid data"
      it_behaves_like "RpiController#create with invalid data"
    end
  end
end
