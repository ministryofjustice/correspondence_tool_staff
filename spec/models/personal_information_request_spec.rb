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
require "rails_helper"

describe PersonalInformationRequest do
  let(:valid_data) do
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

  let(:valid_data_v2) {
    {
      "submission_id": "57188f93-5795-44b2-8544-c5b336298c30",
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
        "upcoming_court_case": "Yes",
        "upcoming_court_case_text": "answer to Tell us more about your upcoming court case or hearing",
      },
      "attachments": [],
    }
  }

  describe "default scope" do
    it "does not return requests whose files have been deleted" do
      request = create(:personal_information_request)
      create(:personal_information_request, deleted: true)

      expect(described_class.all).to eq [request]
    end
  end

  describe ".build" do
    context "when V1 data" do
      it "creates object with data from payload" do
        rpi = described_class.build(valid_data)
        expect(rpi.submission_id).to eq "0fc67a0a-1c58-48ee-baec-36f9f2aaebe3"
      end
    end

    context "when V2 data" do
      it "creates object with data from payload" do
        rpi = described_class.build(valid_data_v2)
        expect(rpi.submission_id).to eq "57188f93-5795-44b2-8544-c5b336298c30"
      end
    end
  end

  describe ".valid_target?" do
    it "returns true for branston" do
      expect(described_class.valid_target?("branston")).to eq true
      expect(described_class.valid_target?(:branston)).to eq true
      expect(described_class.valid_target?(described_class::BRANSTON)).to eq true
    end

    it "returns true for disclosure" do
      expect(described_class.valid_target?("disclosure")).to eq true
      expect(described_class.valid_target?(:disclosure)).to eq true
      expect(described_class.valid_target?(described_class::DISCLOSURE)).to eq true
    end

    it "returns false for other values" do
      expect(described_class.valid_target?("target")).to eq false
      expect(described_class.valid_target?(:target)).to eq false
    end
  end

  describe ".email_for_target" do
    it "returns branston email address" do
      expect(described_class.email_for_target(described_class::BRANSTON)).to eq Settings.emails.branston
    end

    it "returns disclosure email address" do
      expect(described_class.email_for_target(described_class::DISCLOSURE)).to eq Settings.emails.disclosure
    end
  end

  describe "#targets" do
    context "when only branston data" do
      it "returns only branston" do
        rpi = build(:personal_information_request, prison_service_data: "Yes")
        expect(rpi.targets).to eq [:branston]
      end
    end

    context "when only london disclosure data" do
      it "returns only branston" do
        rpi = build(:personal_information_request, laa_data: "Yes")
        expect(rpi.targets).to eq [:disclosure]
      end
    end

    context "when both branston and london disclosure data" do
      it "returns branston and disclosure" do
        rpi = build(:personal_information_request, prison_service_data: "Yes", laa_data: "Yes")
        expect(rpi.targets).to eq %i[branston disclosure]
      end
    end
  end

  describe "#requesting_own_data?" do
    context "when requesting own data" do
      it "returns true" do
        rpi = build(:personal_information_request, requesting_own_data: "Your own")
        expect(rpi).to be_requesting_own_data
      end
    end

    context "when requesting data for someone else" do
      it "returns false" do
        rpi = build(:personal_information_request, requesting_own_data: "Someone else's")
        expect(rpi).not_to be_requesting_own_data
      end
    end
  end

  describe "#request_by_legal_representative?" do
    context "when requesting own data" do
      it "returns false" do
        rpi = build(:personal_information_request, requesting_own_data: "Your own")
        expect(rpi).not_to be_request_by_legal_representative
      end
    end

    context "when requesting others data as friend" do
      it "returns false" do
        rpi = build(:personal_information_request, requesting_own_data: "Someone else's", requestor_relationship: "Relative, friend or something else")
        expect(rpi).not_to be_request_by_legal_representative
      end
    end

    context "when requesting others data as legal representative" do
      it "returns true" do
        rpi = build(:personal_information_request, requesting_own_data: "Someone else's", requestor_relationship: "Legal representative")
        expect(rpi).to be_request_by_legal_representative
      end
    end
  end

  describe "#prison_service_data?" do
    context "when requesting prison service data" do
      it "returns true" do
        rpi = build(:personal_information_request, prison_service_data: "Yes")
        expect(rpi).to be_prison_service_data
      end
    end

    context "when not requesting prison service data" do
      it "returns false" do
        rpi = build(:personal_information_request, prison_service_data: "No")
        expect(rpi).not_to be_prison_service_data
      end
    end
  end

  describe "#probation_service_data?" do
    context "when requesting probation service data" do
      it "returns true" do
        rpi = build(:personal_information_request, probation_service_data: "Yes")
        expect(rpi).to be_probation_service_data
      end
    end

    context "when not requesting probation service data" do
      it "returns false" do
        rpi = build(:personal_information_request, probation_service_data: "No")
        expect(rpi).not_to be_probation_service_data
      end
    end
  end

  describe "#laa_data?" do
    context "when requesting laa data" do
      it "returns true" do
        rpi = build(:personal_information_request, laa_data: "Yes")
        expect(rpi).to be_laa_data
      end
    end

    context "when not requesting laa data" do
      it "returns false" do
        rpi = build(:personal_information_request, laa_data: "No")
        expect(rpi).not_to be_laa_data
      end
    end
  end

  describe "#opg_data?" do
    context "when requesting opg data" do
      it "returns true" do
        rpi = build(:personal_information_request, opg_data: "Yes")
        expect(rpi).to be_opg_data
      end
    end

    context "when not requesting opg data" do
      it "returns false" do
        rpi = build(:personal_information_request, opg_data: "No")
        expect(rpi).not_to be_opg_data
      end
    end
  end

  describe "#other_data?" do
    context "when requesting other data" do
      it "returns true" do
        rpi = build(:personal_information_request, other_data: "Yes")
        expect(rpi).to be_other_data
      end
    end

    context "when not requesting other data" do
      it "returns false" do
        rpi = build(:personal_information_request, other_data: "No")
        expect(rpi).not_to be_other_data
      end
    end
  end

  describe "#currently_in_prison?" do
    context "when requesting own data" do
      it "returns false" do
        rpi = build(:personal_information_request, requesting_own_data: "Your own")
        expect(rpi).not_to be_currently_in_prison
      end
    end

    context "when subject is currently in prison" do
      it "returns true" do
        rpi = build(:personal_information_request, requesting_own_data: "Someone else's", currently_in_prison: "Yes")
        expect(rpi).to be_currently_in_prison
      end
    end

    context "when subject is not currently in prison" do
      it "returns false" do
        rpi = build(:personal_information_request, requesting_own_data: "Someone else's", currently_in_prison: "No")
        expect(rpi).not_to be_currently_in_prison
      end
    end
  end

  describe "#needed_for_court?" do
    context "when information is needed for court" do
      it "returns true" do
        rpi = build(:personal_information_request, needed_for_court: "Yes")
        expect(rpi).to be_needed_for_court
      end
    end

    context "when information is not needed for court" do
      it "returns false" do
        rpi = build(:personal_information_request, needed_for_court: "No")
        expect(rpi).not_to be_needed_for_court
      end
    end
  end

  describe "#attachment_url" do
    context "with branston target" do
      it "returns URL of PDF" do
        rpi = build(:personal_information_request)
        expect(rpi.attachment_url(:branston)).to eq "http://localhost/rpi/branston/#{rpi.submission_id}"
      end
    end

    context "with disclosure target" do
      it "returns URL of PDF" do
        rpi = build(:personal_information_request)
        expect(rpi.attachment_url(:dislosure)).to eq "http://localhost/rpi/dislosure/#{rpi.submission_id}"
      end
    end
  end

  describe "#temporary_url" do
    it "retuns s3 url" do
      rpi = build(:personal_information_request)
      target = :branston
      s3_url = "url/to/file"
      s3_object = instance_double(Aws::S3::Object)
      allow(s3_object).to receive(:presigned_url).and_return(s3_url)
      allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                       .with(rpi.key(target))
                                       .and_return(s3_object)
      expect(rpi.temporary_url(target)).to eq s3_url
    end
  end

  describe "#to_markdown" do
    context "with invalid target" do
      it "raises error" do
        rpi = build(:personal_information_request)
        expect { rpi.to_markdown("invalid") }.to raise_exception(ArgumentError)
      end
    end

    context "with subject information" do
      it "returns who is requesting information" do
        rpi = build(:personal_information_request, requesting_own_data: "Your own")
        expect(rpi.to_markdown(:branston)).to include("Your own")
        expect(rpi.to_markdown(:disclosure)).to include("Your own")
      end

      it "returns subject's name" do
        rpi = build(:personal_information_request, subject_full_name: "name of subject")
        expect(rpi.to_markdown(:branston)).to include("name of subject")
        expect(rpi.to_markdown(:disclosure)).to include("name of subject")
      end

      it "returns subject's other names" do
        rpi = build(:personal_information_request, subject_other_name: "other name of subject")
        expect(rpi.to_markdown(:branston)).to include("other name of subject")
        expect(rpi.to_markdown(:disclosure)).to include("other name of subject")
      end

      it "returns subject's date of birth" do
        rpi = build(:personal_information_request, subject_dob: "1990-01-01")
        expect(rpi.to_markdown(:branston)).to include("1990-01-01")
        expect(rpi.to_markdown(:disclosure)).to include("1990-01-01")
      end

      it "returns subject's photo ID filename" do
        rpi = build(:personal_information_request, subject_photo_id_file_name: "idfile.png")
        expect(rpi.to_markdown(:branston)).to include("idfile.png")
        expect(rpi.to_markdown(:disclosure)).to include("idfile.png")
      end

      it "returns subject's proof of address filename" do
        rpi = build(:personal_information_request, subject_proof_of_address_file_name: "address.png")
        expect(rpi.to_markdown(:branston)).to include("address.png")
        expect(rpi.to_markdown(:disclosure)).to include("address.png")
      end
    end

    context "with requestor information" do
      context "with legal representative" do
        it "returns relationship of requestor to subject" do
          rpi = build(:personal_information_request, :request_as_legal_representative)
          expect(rpi.to_markdown(:branston)).to include("Legal representative")
          expect(rpi.to_markdown(:disclosure)).to include("Legal representative")
        end

        it "returns requestor organization name" do
          rpi = build(:personal_information_request, :request_as_legal_representative, requester_organisation_name: "name of org")
          expect(rpi.to_markdown(:branston)).to include("name of org")
          expect(rpi.to_markdown(:disclosure)).to include("name of org")
        end

        it "returns legal consent filename" do
          rpi = build(:personal_information_request, :request_as_legal_representative, letter_of_consent_file_name: "consent.png")
          expect(rpi.to_markdown(:branston)).to include("consent.png")
          expect(rpi.to_markdown(:disclosure)).to include("consent.png")
        end
      end

      context "with friend or relative" do
        it "returns requestor photo ID filename" do
          rpi = build(:personal_information_request, :request_as_friend, requestor_photo_id_file_name: "requestor_photo.png")
          expect(rpi.to_markdown(:branston)).to include("requestor_photo.png")
          expect(rpi.to_markdown(:disclosure)).to include("requestor_photo.png")
        end

        it "returns requestor proof of adddress filename" do
          rpi = build(:personal_information_request, :request_as_friend, requestor_proof_of_address_file_name: "requestor_address.png")
          expect(rpi.to_markdown(:branston)).to include("requestor_address.png")
          expect(rpi.to_markdown(:disclosure)).to include("requestor_address.png")
        end
      end
    end

    context "with prison service data" do
      it "doesn't return prison service data for disclosure target" do
        rpi = build(:personal_information_request, :with_prison_service_data)
        expect(rpi.to_markdown(:disclosure)).not_to include("**Do you want personal information held by the Prison Service?**")
      end

      it "returns whether prison service data is required" do
        rpi = build(:personal_information_request, :with_prison_service_data)
        expect(rpi.to_markdown(:branston)).to include("**Do you want personal information held by the Prison Service?**\nYes")
      end

      context "when requesting own data" do
        it "returns prison number" do
          rpi = build(:personal_information_request, :with_prison_service_data, subject_prison_number: "12345")
          expect(rpi.to_markdown(:branston)).to include("**What was your prison number?**\n12345")
        end

        it "returns recent prison" do
          rpi = build(:personal_information_request, :with_prison_service_data, previous_prison: "name of prison")
          expect(rpi.to_markdown(:branston)).to include("**Which prison were you most recently in?**\nname of prison")
        end
      end

      context "when requesting other's data" do
        it "returns whether subject is currently in prison" do
          rpi = build(:personal_information_request, :request_as_friend, :with_prison_service_data, currently_in_prison: "Yes")
          expect(rpi.to_markdown(:branston)).to include("**Is the subject currently in prison?**\nYes")
        end

        context "when currently in prison" do
          it "returns current prison" do
            rpi = build(:personal_information_request, :request_as_friend, :with_prison_service_data, currently_in_prison: "Yes", current_prison: "their current prison")
            expect(rpi.to_markdown(:branston)).to include("their current prison")
          end

          it "returns prison number" do
            rpi = build(:personal_information_request, :request_as_friend, :with_prison_service_data, currently_in_prison: "Yes", subject_prison_number: "12345")
            expect(rpi.to_markdown(:branston)).to include("**What is their prison number?**\n12345")
          end
        end

        context "when not currently in prison" do
          it "returns previous prison" do
            rpi = build(:personal_information_request, :request_as_friend, :with_prison_service_data, currently_in_prison: "No", previous_prison: "their previous prison")
            expect(rpi.to_markdown(:branston)).to include("their previous prison")
          end

          it "returns prison number" do
            rpi = build(:personal_information_request, :request_as_friend, :with_prison_service_data, currently_in_prison: "No", subject_prison_number: "12345")
            expect(rpi.to_markdown(:branston)).to include("**What was their prison number?**\n12345")
          end
        end
      end

      it "returns which information is required" do
        rpi = build(:personal_information_request, :with_prison_service_data, prison_information: "details of prison info required")
        expect(rpi.to_markdown(:branston)).to include("details of prison info required")
      end

      it "returns which other information is required" do
        rpi = build(:personal_information_request, :with_prison_service_data, prison_information_other: "details of other prison info required")
        expect(rpi.to_markdown(:branston)).to include("details of other prison info required")
      end

      it "returns date from information is required" do
        rpi = build(:personal_information_request, :with_prison_service_data, prison_data_from: "2000-01-01")
        expect(rpi.to_markdown(:branston)).to include("2000-01-01")
      end

      it "returns date to information is required" do
        rpi = build(:personal_information_request, :with_prison_service_data, prison_data_to: "2003-01-01")
        expect(rpi.to_markdown(:branston)).to include("2003-01-01")
      end
    end

    context "with probation service data" do
      it "doesn't return prison service data for disclosure target" do
        rpi = build(:personal_information_request, :with_probation_service_data)
        expect(rpi.to_markdown(:disclosure)).not_to include("**Do you want personal information held by the Probation Service?**")
      end

      it "returns whether probation service data is required" do
        rpi = build(:personal_information_request, :with_probation_service_data)
        expect(rpi.to_markdown(:branston)).to include("**Do you want personal information held by the Probation Service?**\nYes")
      end

      it "returns which information is required" do
        rpi = build(:personal_information_request, :with_probation_service_data, probation_information: "details of probation info required")
        expect(rpi.to_markdown(:branston)).to include("details of probation info required")
      end

      it "returns which other information is required" do
        rpi = build(:personal_information_request, :with_probation_service_data, probation_information_other: "details of other probation info required")
        expect(rpi.to_markdown(:branston)).to include("details of other probation info required")
      end

      it "returns date from information is required" do
        rpi = build(:personal_information_request, :with_probation_service_data, probation_data_from: "2012-01-01")
        expect(rpi.to_markdown(:branston)).to include("2012-01-01")
      end

      it "returns date to information is required" do
        rpi = build(:personal_information_request, :with_probation_service_data, probation_data_to: "2013-01-01")
        expect(rpi.to_markdown(:branston)).to include("2013-01-01")
      end
    end

    context "with LAA data" do
      it "doesn't return prison service data for branston target" do
        rpi = build(:personal_information_request, :with_laa_data)
        expect(rpi.to_markdown(:branston)).not_to include("**Do you want personal information held by the Legal Aid Agency (LAA)?**")
      end

      it "returns whether LAA data is required" do
        rpi = build(:personal_information_request, :with_laa_data)
        expect(rpi.to_markdown(:disclosure)).to include("**Do you want personal information held by the Legal Aid Agency (LAA)?**\nYes")
      end

      it "returns which information is required" do
        rpi = build(:personal_information_request, :with_laa_data, laa_information: "details of laa info required")
        expect(rpi.to_markdown(:disclosure)).to include("details of laa info required")
      end

      it "returns date from information is required" do
        rpi = build(:personal_information_request, :with_laa_data, laa_data_from: "2015-01-01")
        expect(rpi.to_markdown(:disclosure)).to include("2015-01-01")
      end

      it "returns date to information is required" do
        rpi = build(:personal_information_request, :with_laa_data, laa_data_to: "2016-01-01")
        expect(rpi.to_markdown(:disclosure)).to include("2016-01-01")
      end
    end

    context "with OPG data" do
      it "doesn't return prison service data for branston target" do
        rpi = build(:personal_information_request, :with_opg_data)
        expect(rpi.to_markdown(:branston)).not_to include("**Do you want personal information held by the Office of the Public Guardian (OPG)?**")
      end

      it "returns whether OPG data is required" do
        rpi = build(:personal_information_request, :with_opg_data)
        expect(rpi.to_markdown(:disclosure)).to include("**Do you want personal information held by the Office of the Public Guardian (OPG)?**\nYes")
      end

      it "returns which information is required" do
        rpi = build(:personal_information_request, :with_opg_data, opg_information: "details of opg info required")
        expect(rpi.to_markdown(:disclosure)).to include("details of opg info required")
      end

      it "returns date from information is required" do
        rpi = build(:personal_information_request, :with_opg_data, opg_data_from: "2017-01-01")
        expect(rpi.to_markdown(:disclosure)).to include("2017-01-01")
      end

      it "returns date to information is required" do
        rpi = build(:personal_information_request, :with_opg_data, opg_data_to: "2018-01-01")
        expect(rpi.to_markdown(:disclosure)).to include("2018-01-01")
      end
    end

    context "with data from elsewhere in MOJ" do
      it "doesn't return prison service data for branston target" do
        rpi = build(:personal_information_request, :with_other_data)
        expect(rpi.to_markdown(:branston)).not_to include("**Do you want personal information held by another part of the Ministry of Justice?**")
      end

      it "returns whether other data is required" do
        rpi = build(:personal_information_request, :with_other_data)
        expect(rpi.to_markdown(:disclosure)).to include("**Do you want personal information held by another part of the Ministry of Justice?**\nYes")
      end

      it "returns which information is required" do
        rpi = build(:personal_information_request, :with_other_data, other_information: "details of other info required")
        expect(rpi.to_markdown(:disclosure)).to include("details of other info required")
      end

      it "returns date from information is required" do
        rpi = build(:personal_information_request, :with_other_data, other_data_from: "2020-01-01")
        expect(rpi.to_markdown(:disclosure)).to include("2020-01-01")
      end

      it "returns date to information is required" do
        rpi = build(:personal_information_request, :with_other_data, other_data_to: "2021-01-01")
        expect(rpi.to_markdown(:disclosure)).to include("2021-01-01")
      end
    end

    context "with contact information" do
      it "returns contact address" do
        rpi = build(:personal_information_request, contact_address: "Contact address\n somewhere in the country")
        expect(rpi.to_markdown(:branston)).to include("Contact address\n somewhere in the country")
      end

      it "returns contact email" do
        rpi = build(:personal_information_request, contact_email: "email@domain.com")
        expect(rpi.to_markdown(:branston)).to include("email@domain.com")
      end
    end

    context "with court information" do
      it "returns if information is needed for court" do
        rpi = build(:personal_information_request)
        expect(rpi.to_markdown(:branston)).to include("**Do you need this information for an upcoming court case or hearing?**\nNo")
      end

      context "when information is needed for court" do
        it "returns contact address" do
          rpi = build(:personal_information_request, :needed_for_court, needed_for_court_information: "info about why needed for court")
          expect(rpi.to_markdown(:branston)).to include("info about why needed for court")
        end
      end
    end
  end
end
