require "rails_helper"

RSpec.describe Api::RpiV2Controller, type: :controller do
  let(:json) do
    {
      "submission_id": "0fc67a0a-1c58-48ee-baec-36f9f2aaebe3",
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
      },
      "attachments": [],
    }.to_json
  end

  describe "authenticates the request" do
    context "with no body" do
      it "responds with 401" do
        post(:create)
        expect(response.status).to eq 401
      end
    end

    context "with json payload" do
      it "parses the body" do
        post(:create, body: json)
        expect(assigns(:body)).to eq JSON.parse(json, symbolize_names: true)
      end
    end
  end

  describe "#create" do
    it "Creates a job to process the payload" do
      expect(RequestPersonalInformationJob).to receive(:perform_later)
      post(:create, body: json)
    end
  end
end
