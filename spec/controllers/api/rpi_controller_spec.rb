require "rails_helper"

RSpec.describe Api::RpiController, type: :controller do
  let(:unencrypted_json) do
    {
      "serviceSlug": "request-personal-information-migrate",
      "submissionId": "0fc67a0a-1c58-48ee-baec-36f9f2aaebe3",
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
    }.to_json
  end

  let(:encrypted_json) { JWE.encrypt(unencrypted_json, Settings.rpi_jwe_key, alg: "dir") }

  let(:invalid_json_body) do
    {
      invalid: "json",
    }.to_json
  end

  describe "authenticates the request" do
    context "with no body" do
      it "responds with 401" do
        post(:create)
        expect(response.status).to eq 401
      end
    end

    context "with invalid data" do
      it "responds with 401" do
        post(:create, body: invalid_json_body)
        expect(response.status).to eq 401
      end
    end

    context "with encrypted json payload" do
      it "decrypts the body" do
        post(:create, body: encrypted_json)
        expect(assigns(:decrypted_body)).to eq JSON.parse(unencrypted_json, symbolize_names: true)
      end
    end
  end

  describe "#create" do
    it "Creates a job to process the payload" do
      expect(RequestPersonalInformationJob).to receive(:perform_later)
      post(:create, body: encrypted_json)
    end
  end
end
