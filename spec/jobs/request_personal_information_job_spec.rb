require "rails_helper"

describe RequestPersonalInformationJob, type: :job do
  include ActiveJob::TestHelper

  let(:payload) do
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
    }
  end

  before do
    ActiveJob::Base.queue_adapter = :test
    # attachment = instance_double CaseAttachment
    allow(SentryContextProvider).to receive(:set_context)
    # allow(CaseAttachment).to receive(:find).with(123).and_return(attachment)
    # allow(attachment).to receive(:make_preview)
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  describe ".perform" do
    it "sets the Sentry environment" do
      described_class.perform_now(payload)
      expect(SentryContextProvider).to have_received(:set_context)
    end

    it "queues the job" do
      expect { described_class.perform_later(payload) }.to have_enqueued_job(described_class)
    end

    it "is in expected queue" do
      expect(described_class.new.queue_name).to eq("correspondence_tool_staff_rpi")
    end

    it "executes perform" do
      expect(ActionNotificationsMailer).to receive(:rpi_email).with(PersonalInformationRequest, anything).at_least(:once).and_call_original
      perform_enqueued_jobs { described_class.perform_later(payload) }
    end
  end
end
