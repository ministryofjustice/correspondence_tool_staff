require "rails_helper"

describe RequestPersonalInformation::RequestBuilder do
  subject(:builder) { described_class.new(rpi) }

  let(:rpi) { PersonalInformationRequest.new }
  let(:base_data) do
    {
      submission_id: "abcdef",
      contact_address: "contact address",
      contact_email: "email@email.com",
      needed_for_court: "Yes",
      needed_for_court_information: "Info needed",
      prison_service_data: "No",
      probation_service_data: "No",
      laa_data: "No",
      opg_data: "No",
      other_data: "No",
    }
  end
  let(:base_own_date) do
    base_data.merge({
      requesting_own_data: "Your own",
      personal_data_full_name: "My name",
      personal_data_other_name: "Other name",
      personal_data_dob: "1981-04-12",
      photo_id_file_name: "photo_id_name.jpg",
      proof_of_address_file_name: "proof_of_address.jpg",
    })
  end
  let(:base_other_data) do
    base_data.merge({
      requesting_own_data: "Someone else's",
      data_subject_full_name: "subject name",
      data_subject_other_name: "subject other name",
      data_subject_dob: "2075-04-12",
      data_subject_relationship: "Relative, friend or something else",
      requestor_name: "Name of requestor",
      photo_id_file_name: "photo.jpg",
      proof_of_address_file_name: "address.jpg",
      subject_photo_id_file_name: "subject_photo.jpg",
      subject_proof_of_address_file_name: "subject_address.jpg",
      letter_of_consent_file_name: "consent.jpg",
    })
  end
  let(:specific_data) { {} }
  let(:own_data) { instance_double(RequestPersonalInformation::Data, base_own_date.merge(specific_data)) }
  let(:other_data) { instance_double(RequestPersonalInformation::Data, base_other_data.merge(specific_data)) }

  describe "#build" do
    it "adds submission ID to PersonalInformationRequest object" do
      builder.build(own_data)
      expect(rpi.submission_id).to eq "abcdef"
    end

    context "when requesting own data" do
      before { builder.build(own_data) }

      it "updates data in PersonalInformationRequest object" do
        expect(rpi.requesting_own_data).to eq "Your own"
        expect(rpi.subject_full_name).to eq "My name"
        expect(rpi.subject_other_name).to eq "Other name"
        expect(rpi.subject_dob).to eq "1981-04-12"
        expect(rpi.subject_photo_id_file_name).to eq "photo_id_name.jpg"
        expect(rpi.subject_proof_of_address_file_name).to eq "proof_of_address.jpg"
        expect(rpi.contact_address).to eq "contact address"
        expect(rpi.contact_email).to eq "email@email.com"
        expect(rpi.needed_for_court).to eq "Yes"
        expect(rpi.needed_for_court_information).to eq "Info needed"
      end

      context "when requesting prison service data" do
        let(:specific_data) do
          {
            prison_service_data: "Yes",
            prison_number: "12345",
            previous_prison: "prison name",
            prison_information: "prison info",
            prison_information_other: "other info",
            prison_data_from: "2001-01-02",
            prison_data_to: "2002-01-01",
          }
        end

        it "updates data in PersonalInformationRequest object" do
          expect(rpi.prison_service_data).to eq "Yes"
          expect(rpi.subject_prison_number).to eq "12345"
          expect(rpi.previous_prison).to eq "prison name"
          expect(rpi.prison_information).to eq "prison info"
          expect(rpi.prison_information_other).to eq "other info"
          expect(rpi.prison_data_from).to eq "2001-01-02"
          expect(rpi.prison_data_to).to eq "2002-01-01"
        end
      end

      context "when requesting probation service data" do
        let(:specific_data) do
          {
            probation_service_data: "Yes",
            probation_office: "Name of office",
            probation_information: "info requested",
            probation_information_other: "other info requested",
            probation_data_from: "2019-01-01",
            probation_data_to: "2021-01-01",
          }
        end

        it "updates data in PersonalInformationRequest object" do
          expect(rpi.probation_service_data).to eq "Yes"
          expect(rpi.probation_office).to eq "Name of office"
          expect(rpi.probation_information).to eq "info requested"
          expect(rpi.probation_information_other).to eq "other info requested"
          expect(rpi.probation_data_from).to eq "2019-01-01"
          expect(rpi.probation_data_to).to eq "2021-01-01"
        end
      end
    end

    context "when requesting friend's data" do
      before { builder.build(other_data) }

      it "updates data in PersonalInformationRequest object" do
        expect(rpi.requesting_own_data).to eq "Someone else's"
        expect(rpi.subject_full_name).to eq "subject name"
        expect(rpi.subject_other_name).to eq "subject other name"
        expect(rpi.subject_dob).to eq "2075-04-12"
        expect(rpi.requestor_relationship).to eq "Relative, friend or something else"
        expect(rpi.requestor_name).to eq "Name of requestor"
        expect(rpi.requestor_photo_id_file_name).to eq "photo.jpg"
        expect(rpi.requestor_proof_of_address_file_name).to eq "address.jpg"
        expect(rpi.subject_photo_id_file_name).to eq "subject_photo.jpg"
        expect(rpi.subject_proof_of_address_file_name).to eq "subject_address.jpg"
        expect(rpi.letter_of_consent_file_name).to eq "consent.jpg"
      end

      context "when requesting prison service data when in prison" do
        let(:specific_data) do
          {
            prison_service_data: "Yes",
            currently_in_prison: "Yes",
            subject_prison_number: "ABCD123",
            subject_current_prison: "name of current prison",
            prison_information: "prison info",
            prison_information_other: "other info",
            prison_data_from: "2001-01-02",
            prison_data_to: "2002-01-01",
          }
        end

        it "updates data in PersonalInformationRequest object" do
          expect(rpi.prison_service_data).to eq "Yes"
          expect(rpi.currently_in_prison).to eq "Yes"
          expect(rpi.subject_prison_number).to eq "ABCD123"
          expect(rpi.current_prison).to eq "name of current prison"
          expect(rpi.prison_information).to eq "prison info"
          expect(rpi.prison_information_other).to eq "other info"
          expect(rpi.prison_data_from).to eq "2001-01-02"
          expect(rpi.prison_data_to).to eq "2002-01-01"
        end
      end

      context "when requesting prison service data when not in prison" do
        let(:specific_data) do
          {
            prison_service_data: "Yes",
            currently_in_prison: "No",
            subject_prison_number: "ABCD123",
            subject_previous_prison: "name of previous prison",
            prison_information: "prison info",
            prison_information_other: "other info",
            prison_data_from: "2001-01-02",
            prison_data_to: "2002-01-01",
          }
        end

        it "updates data in PersonalInformationRequest object" do
          expect(rpi.prison_service_data).to eq "Yes"
          expect(rpi.currently_in_prison).to eq "No"
          expect(rpi.subject_prison_number).to eq "ABCD123"
          expect(rpi.previous_prison).to eq "name of previous prison"
          expect(rpi.prison_information).to eq "prison info"
          expect(rpi.prison_information_other).to eq "other info"
          expect(rpi.prison_data_from).to eq "2001-01-02"
          expect(rpi.prison_data_to).to eq "2002-01-01"
        end
      end

      context "when requesting probation service data" do
        let(:specific_data) do
          {
            probation_service_data: "Yes",
            subject_probation_office: "Name of their office",
            probation_information: "info requested",
            probation_information_other: "other info requested",
            probation_data_from: "2019-01-01",
            probation_data_to: "2021-01-01",
          }
        end

        it "updates data in PersonalInformationRequest object" do
          expect(rpi.probation_service_data).to eq "Yes"
          expect(rpi.probation_office).to eq "Name of their office"
          expect(rpi.probation_information).to eq "info requested"
          expect(rpi.probation_information_other).to eq "other info requested"
          expect(rpi.probation_data_from).to eq "2019-01-01"
          expect(rpi.probation_data_to).to eq "2021-01-01"
        end
      end
    end

    context "when requesting client's data" do
      before { builder.build(other_data) }

      let(:specific_data) do
        {
          data_subject_relationship: "Legal representative",
          legal_representative_organisation_name: "legal org name",
          legal_representative_name: "Name of requestor",
        }
      end

      it "updates data in PersonalInformationRequest object" do
        expect(rpi.requesting_own_data).to eq "Someone else's"
        expect(rpi.subject_full_name).to eq "subject name"
        expect(rpi.subject_other_name).to eq "subject other name"
        expect(rpi.subject_dob).to eq "2075-04-12"
        expect(rpi.requestor_relationship).to eq "Legal representative"
        expect(rpi.requester_organisation_name).to eq "legal org name"
        expect(rpi.requestor_name).to eq "Name of requestor"
        expect(rpi.letter_of_consent_file_name).to eq "consent.jpg"
      end
    end

    context "when requesting LAA data" do
      before { builder.build(own_data) }

      let(:specific_data) do
        {
          laa_data: "Yes",
          laa_information: "laa info",
          laa_data_from: "1990-01-01",
          laa_data_to: "1995-01-01",
        }
      end

      it "updates data in PersonalInformationRequest object" do
        expect(rpi.laa_data).to eq "Yes"
        expect(rpi.laa_information).to eq "laa info"
        expect(rpi.laa_data_from).to eq "1990-01-01"
        expect(rpi.laa_data_to).to eq "1995-01-01"
      end
    end

    context "when requesting OPG data" do
      before { builder.build(own_data) }

      let(:specific_data) do
        {
          opg_data: "Yes",
          opg_information: "opg info",
          opg_data_from: "1992-01-01",
          opg_data_to: "1996-01-01",
        }
      end

      it "updates data in PersonalInformationRequest object" do
        expect(rpi.opg_data).to eq "Yes"
        expect(rpi.opg_information).to eq "opg info"
        expect(rpi.opg_data_from).to eq "1992-01-01"
        expect(rpi.opg_data_to).to eq "1996-01-01"
      end
    end

    context "when requesting other MOJ data" do
      before { builder.build(own_data) }

      let(:specific_data) do
        {
          other_data: "Yes",
          other_information: "other moj info",
          other_data_from: "1990-05-01",
          other_data_to: "1995-05-01",
          other_where: "where it is",
        }
      end

      it "updates data in PersonalInformationRequest object" do
        expect(rpi.other_data).to eq "Yes"
        expect(rpi.other_information).to eq "other moj info"
        expect(rpi.other_data_from).to eq "1990-05-01"
        expect(rpi.other_data_to).to eq "1995-05-01"
        expect(rpi.other_where).to eq "where it is"
      end
    end
  end
end
