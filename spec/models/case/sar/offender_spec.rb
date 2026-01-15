# == Schema Information
#
# Table name: cases
#
#  id                       :integer          not null, primary key
#  name                     :string
#  email                    :string
#  message                  :text
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  received_date            :date
#  postal_address           :string
#  subject                  :string
#  properties               :jsonb
#  requester_type           :enum
#  number                   :string           not null
#  date_responded           :date
#  outcome_id               :integer
#  refusal_reason_id        :integer
#  current_state            :string
#  last_transitioned_at     :datetime
#  delivery_method          :enum
#  workflow                 :string
#  deleted                  :boolean          default(FALSE)
#  info_held_status_id      :integer
#  type                     :string
#  appeal_outcome_id        :integer
#  dirty                    :boolean          default(FALSE)
#  reason_for_deletion      :string
#  user_id                  :integer          default(-100), not null
#  reason_for_lateness_id   :bigint
#  reason_for_lateness_note :string
#

require "rails_helper"

describe Case::SAR::Offender do
  context "when valid offender factory should be valid" do
    it "is valid" do
      kase = build_stubbed :offender_sar_case

      expect(kase).to be_valid
    end
  end

  context "when validates that SAR-specific fields are not blank" do
    it "is not valid" do
      kase = build_stubbed :offender_sar_case, subject_full_name: nil, subject_type: nil, third_party: nil, flag_as_high_profile: nil, flag_as_dps_missing_data: nil

      expect(kase).not_to be_valid
      expect(kase.errors[:subject_full_name]).to eq(["cannot be blank"])
      expect(kase.errors[:third_party]).to eq(["cannot be blank"])
      expect(kase.errors[:flag_as_high_profile]).to eq(["cannot be blank"])
    end
  end

  describe "predicate methods" do
    describe "#type_of_offender_sar?" do
      it "is a sort of offender_sar" do
        kase = build_stubbed :offender_sar_case
        expect(kase.type_of_offender_sar?).to be true
      end
    end

    describe "#offender_sar?" do
      it "is offender_sar standard" do
        kase = build_stubbed :offender_sar_case
        expect(kase.offender_sar?).to be true
      end
    end

    describe "#offender_sar_complaint?" do
      it "is not an offender_sar complaint" do
        kase = build_stubbed :offender_sar_case
        expect(kase.offender_sar_complaint?).to be false
      end
    end
  end

  describe "#external_deadline for rejected" do
    let(:rejected_offender_sar_case) { create(:offender_sar_case, :rejected) }

    it "sets external deadline using a calculation of 90 days from received_date" do
      expect(rejected_offender_sar_case.external_deadline).to eq(Time.zone.today + 90)
    end
  end

  describe "#external_deadline for case flagged as dps missing data rejected sar" do
    let(:rejected_offender_sar_case) { create(:offender_sar_case, :rejected, flag_as_dps_missing_data: true) }

    it "sets external deadline using a calculation of 60 days from received_date" do
      expect(rejected_offender_sar_case.external_deadline).to eq(Time.zone.today + 60)
    end
  end

  describe "#external_deadline for case not flagged as a dps missing data rejected sar" do
    let(:rejected_offender_sar_case) { create(:offender_sar_case, :rejected, flag_as_dps_missing_data: false) }

    it "sets external deadline using a calculation of 90 days from received_date" do
      expect(rejected_offender_sar_case.external_deadline).to eq(Time.zone.today + 90)
    end
  end

  describe ".close_expired_rejected" do
    let(:rejected_expired) { create(:offender_sar_case, :rejected) }
    let(:system_user) { User.system_admin }

    before do
      rejected_expired.update!(external_deadline: Date.yesterday)

      create(:offender_sar_case) # not rejected
      create(:offender_sar_case, :rejected) # rejected
    end

    it "calls CaseClosureService for each expired rejected case" do
      expect(CaseClosureService).to receive(:new).with(rejected_expired, system_user, {}).and_call_original
      described_class.close_expired_rejected
    end
  end

  describe "#rejected_reasons" do
    context "when the rejected reason other checkbox is selected and a reason is given" do
      let(:case_rejected) { create(:offender_sar_case, :rejected, rejected_reasons: %w[other], other_rejected_reason: "More information") }

      it "sets the rejected reason" do
        expect(case_rejected.rejected_reasons).to eq(%w[other])
        expect(case_rejected.other_rejected_reason).to eq("More information")
      end
    end

    context "when the rejected reason other checkbox is de-selected and a reason is present" do
      let(:case_rejected) { create(:offender_sar_case, :rejected, rejected_reasons: %w[other], other_rejected_reason: "More information") }

      it "sets the other rejected reason to blank" do
        case_rejected.update!(rejected_reasons: %w[cctv_bwcf])

        expect(case_rejected.rejected_reasons).to eq(%w[cctv_bwcf])
        expect(case_rejected.other_rejected_reason).to eq("")
      end
    end
  end

  describe "#set_number" do
    let(:case_rejected) { create(:offender_sar_case, :rejected) }
    let(:kase) { create(:offender_sar_case) }

    it "sets the prefix for rejected case" do
      expect(case_rejected.number[0]).to eq("R")
    end

    it "does not set the prefix for a non rejected case" do
      expect(kase.number[0]).to eq("2")
    end
  end

  describe "#set_valid_case_number" do
    let(:case_rejected) { create(:offender_sar_case, :rejected, received_date: Date.parse("11/04/2024"), flag_as_dps_missing_data: false) }
    let(:case_rejected_dps_missing) { create(:offender_sar_case, :rejected, received_date: Date.parse("11/04/2024"), flag_as_dps_missing_data: true) }

    it "does not create a non unique number and does remove the preceding 'R'" do
      expect(case_rejected.set_valid_case_number).not_to eq "240411001"
      expect(case_rejected.set_valid_case_number[0]).not_to eq "R"
    end

    it "creates a unique new number for the valid case" do
      expect(case_rejected.set_valid_case_number).to eq "240411002"
    end

    it "adds the 'D' prefix to the number" do
      expect(case_rejected_dps_missing.flag_as_dps_missing_data?).to eq true
      expect(case_rejected_dps_missing.set_valid_case_number[0]).to eq "D"
    end
  end

  describe "#prevent_number_change" do
    context "when a rejected offender SAR" do
      let(:case_rejected) { create(:offender_sar_case, :rejected) }

      it "does not raise StandardError" do
        case_rejected.number = "987654321"
        expect { case_rejected.save! }.not_to raise_error
      end
    end

    context "when a valid offender SAR" do
      let(:kase) { create(:offender_sar_case) }

      it "raises StandardError" do
        kase.number = "987654321"
        expect { kase.save! }.to raise_error(StandardError, "number is immutable")
      end
    end
  end

  describe "#request_method" do
    context "with valid values" do
      it "does not error" do
        expect(build_stubbed(:offender_sar_case, request_method: "web_portal")).to be_valid
        expect(build_stubbed(:offender_sar_case, request_method: "post")).to be_valid
        expect(build_stubbed(:offender_sar_case, request_method: "email")).to be_valid
        expect(build_stubbed(:offender_sar_case, request_method: "unknown")).to be_valid
      end
    end

    context "with invalid value" do
      it "errors" do
        expect {
          build_stubbed(:offender_sar_case, request_method: "test")
        }.to raise_error ArgumentError
      end
    end

    context "with nil" do
      it "errors" do
        kase = build_stubbed(:offender_sar_case, request_method: nil)
        expect(kase).not_to be_valid
        expect(kase.errors[:request_method]).to eq ["can't be blank"]
      end
    end
  end

  describe "#subject_type" do
    context "with valid values" do
      it "does not error" do
        expect(build_stubbed(:offender_sar_case, subject_type: "detainee")).to be_valid
        expect(build_stubbed(:offender_sar_case, subject_type: "ex_detainee")).to be_valid
        expect(build_stubbed(:offender_sar_case, subject_type: "ex_offender")).to be_valid
        expect(build_stubbed(:offender_sar_case, subject_type: "ex_probation_service_user")).to be_valid
        expect(build_stubbed(:offender_sar_case, subject_type: "offender")).to be_valid
        expect(build_stubbed(:offender_sar_case, subject_type: "probation_service_user")).to be_valid
      end
    end

    context "with invalid value" do
      it "errors" do
        expect {
          build_stubbed(:offender_sar_case, subject_type: "plumber")
        }.to raise_error ArgumentError
      end
    end

    context "with nil" do
      it "errors" do
        kase = build_stubbed(:offender_sar_case, subject_type: nil)
        expect(kase).not_to be_valid
        expect(kase.errors[:subject_type]).to eq ["cannot be blank"]
      end
    end
  end

  describe "#recipient" do
    context "with valid values" do
      it "does not error" do
        expect(build_stubbed(:offender_sar_case, recipient: "subject_recipient")).to be_valid
        expect(build_stubbed(:offender_sar_case, recipient: "requester_recipient")).to be_valid
        expect(build_stubbed(:offender_sar_case,
                             recipient: "third_party_recipient",
                             third_party: false,
                             third_party_name: "test",
                             third_party_relationship: "test")).to be_valid
      end
    end

    context "with invalid value" do
      it "errors" do
        expect {
          build_stubbed(:offender_sar_case, recipient: "user")
        }.to raise_error ArgumentError
      end
    end

    context "with nil" do
      it "errors" do
        kase = build_stubbed(:offender_sar_case, recipient: nil)
        expect(kase).not_to be_valid
        expect(kase.errors[:recipient]).to eq ["cannot be blank"]
      end
    end
  end

  describe "#postal_address" do
    context "with valid values" do
      it "validates when address is set" do
        kase = build_stubbed(:offender_sar_case, :third_party, postal_address: "22 Acacia Avenue")
        expect(kase).to be_valid
      end
    end

    context "with invalid values" do
      it "validates presence of postal address when recipient is third party" do
        kase = build_stubbed :offender_sar_case, :third_party, postal_address: ""
        expect(kase).not_to be_valid
        expect(kase.errors[:postal_address]).to eq ["cannot be blank"]
      end
    end
  end

  describe "#date_of_birth" do
    let(:kase) { build_stubbed :offender_sar_case }

    context "with valid values" do
      it "validates date of birth" do
        expect(kase).to validate_presence_of(:date_of_birth)
        expect(kase).to allow_values("01-01-1967").for(:date_of_birth)
        expect { kase.validate_date_of_birth }.not_to change(kase.errors, :count)
      end
    end

    context "with invalid value" do
      it "is not valid" do
        kase[:date_of_birth] = "wibble"
        expect { kase.validate_date_of_birth }.to change(kase.errors, :count)
      end
    end

    context "with all zeroes value" do
      it "is not valid" do
        kase[:date_of_birth] = "0000-00-00"
        expect { kase.validate_date_of_birth }.to change(kase.errors, :count)
      end
    end

    context "when date of birth cannot be in future" do
      it "errors" do
        kase = build_stubbed(:offender_sar_case, date_of_birth: 1.day.from_now)
        expect(kase).not_to be_valid
        expect(kase.errors[:date_of_birth]).to eq ["cannot be in the future."]
      end
    end

    context "with nil" do
      it "errors" do
        kase = build_stubbed(:offender_sar_case, date_of_birth: nil)
        expect(kase).not_to be_valid
        expect(kase.errors[:date_of_birth]).to eq ["cannot be blank"]
      end
    end
  end

  describe "#received_date" do
    context "with valid values" do
      it "validates received date" do
        kase = build_stubbed :offender_sar_case
        test_date = 4.business_days.ago.strftime("%d-%m-%Y")

        expect(kase).to validate_presence_of(:received_date)
        expect(kase).to allow_values(test_date).for(:received_date)
      end
    end

    context "with invalid value" do
      it "errors" do
        expect {
          build_stubbed(:offender_sar_case, received_date: "wibble")
        }.to raise_error ArgumentError
      end
    end

    context "when received date cannot be in future" do
      it "errors" do
        kase = build_stubbed(:offender_sar_case, received_date: 1.day.from_now)
        expect(kase).not_to be_valid
        expect(kase.errors[:received_date]).to eq ["cannot be in the future."]
      end
    end
  end

  describe "#request_dated" do
    context "with invalid value" do
      it "errors" do
        expect {
          build_stubbed(:offender_sar_case, request_dated: "wibble")
        }.to raise_error ArgumentError
      end
    end

    context "when request_dated date cannot be in future" do
      it "errors" do
        kase = build_stubbed(:offender_sar_case, request_dated: 1.day.from_now)
        expect(kase).not_to be_valid
        expect(kase.errors[:request_dated]).to eq ["cannot be in the future."]
      end
    end
  end

  describe "number_exempt_pages" do
    context "with invalid values" do
      it "errors when float is used" do
        kase = build_stubbed(:offender_sar_case, number_exempt_pages: -562)
        expect(kase).not_to be_valid
        expect(kase.errors[:number_exempt_pages]).to eq ["must be a positive whole number"]
      end
    end

    context "with valid values" do
      it "is valid when string represents a positive whole number" do
        kase = build_stubbed(:offender_sar_case, number_exempt_pages: 4835)
        expect(kase).to be_valid
      end
    end
  end

  describe "number_final_pages" do
    context "with invalid values" do
      it "errors when string represents a negative whole number" do
        kase = build_stubbed(:offender_sar_case, number_final_pages: -562)
        expect(kase).not_to be_valid
        expect(kase.errors[:number_final_pages]).to eq ["must be a positive whole number"]
      end
    end

    context "with valid values" do
      it "is valid when string represents a positive whole number" do
        kase = build_stubbed(:offender_sar_case, number_final_pages: 4835)
        expect(kase).to be_valid
      end
    end
  end

  describe "when creating a rejected case" do
    it "sets case_originally_rejected to true" do
      kase = create :offender_sar_case, :rejected
      expect(kase.case_originally_rejected).to eq true
    end
  end

  describe "third party details" do
    describe "with third_party_names" do
      it "validates third party names when third party is true" do
        kase = build_stubbed :offender_sar_case, :third_party, third_party_name: "", third_party_company_name: ""
        expect(kase).not_to be_valid
        expect(kase.errors[:third_party_name]).to eq ["cannot be blank if company name not given"]
        expect(kase.errors[:third_party_company_name]).to eq ["cannot be blank if representative name not given"]
      end

      it "validates third party names when recipient is third party" do
        kase = build_stubbed :offender_sar_case, third_party: false, third_party_name: "",
                                                 third_party_company_name: "", recipient: "third_party_recipient"
        expect(kase).not_to be_valid
        expect(kase.errors[:third_party_name]).to eq ["cannot be blank if company name not given"]
        expect(kase.errors[:third_party_company_name]).to eq ["cannot be blank if representative name not given"]
      end

      it "does not validate third_party names when recipient is not third party too" do
        kase = build_stubbed :offender_sar_case, third_party: false, third_party_name: "",
                                                 third_party_company_name: "", recipient: "subject_recipient"
        expect(kase).to be_valid
      end
    end

    describe "third party relationship" do
      it "must be present when thrid party is true" do
        kase = build_stubbed :offender_sar_case, third_party: true, third_party_relationship: ""
        expect(kase).not_to be_valid
        expect(kase.errors[:third_party_relationship]).to eq ["cannot be blank"]
      end

      it "must be present when third party is false but recipient is third party" do
        kase = build_stubbed :offender_sar_case, third_party: false, third_party_relationship: "",
                                                 recipient: "third_party_recipient"
        expect(kase).not_to be_valid
        expect(kase.errors[:third_party_relationship]).to eq ["cannot be blank"]
      end

      it "does not validate presence of third party relationship when recipient is not third party" do
        kase = build_stubbed :offender_sar_case, third_party: false, third_party_relationship: "",
                                                 third_party_email: "", third_party_company_name: "", recipient: "subject_recipient"
        expect(kase).to be_valid
      end
    end

    describe "third party email" do
      it "validates email address when there is an email address entered" do
        kase = build_stubbed :offender_sar_case, third_party: true, third_party_relationship: "Solicitor",
                                                 third_party_email: "email", third_party_company_name: "",
                                                 recipient: "third_party_recipient"

        expect(kase).not_to be_valid raise_error(ActiveRecord::RecordInvalid).with_message("invalid format for email address")
      end

      it "does not validate email address when there is no email address entered" do
        kase = build_stubbed :offender_sar_case, third_party: true, third_party_relationship: "Solicitor",
                                                 third_party_email: "", third_party_company_name: "ABC LLP",
                                                 recipient: "third_party_recipient"

        expect(kase).to be_valid
      end

      it "validates email address when the email address entered is the correct format" do
        kase = build_stubbed :offender_sar_case, third_party: true, third_party_relationship: "Solicitor",
                                                 third_party_email: "email@something.com", third_party_company_name: "ABC LLP",
                                                 recipient: "third_party_recipient"

        expect(kase).to be_valid
      end
    end
  end

  describe "#subject" do
    it "is the same as subject full name" do
      kase = create :offender_sar_case
      expect(kase.subject).to eq kase.subject_full_name
      kase.update!(subject_full_name: "Bob Hope")
      expect(kase.subject).to eq "Bob Hope"
    end
  end

  describe "#subject_name" do
    it "is the same as subject_full_name" do
      kase = create :offender_sar_case
      expect(kase.subject_name).to eq kase.subject_full_name
      kase.update!(subject_full_name: "Bob Hope")
      expect(kase.subject_name).to eq "Bob Hope"
    end
  end

  describe "#subject_address" do
    it "returns a dummy string for now" do
      kase = create :offender_sar_case
      expect(kase.subject_address).to eq "22 Sample Address, Test Lane, Testingington, TE57ST"
    end

    it "validates presence of subject address" do
      kase = build_stubbed :offender_sar_case, subject_address: ""
      expect(kase).not_to be_valid
      expect(kase.errors[:subject_address]).to eq ["cannot be blank"]
    end
  end

  describe "#third_party_address" do
    it "wraps the postal_address field" do
      kase = create :offender_sar_case
      expect(kase.third_party_address).to eq kase.postal_address
      kase.update!(postal_address: "11 The Road")
      expect(kase.third_party_address).to eq "11 The Road"
    end
  end

  describe "#requester_name" do
    it "returns third_party_name if third_party request" do
      kase = create :offender_sar_case, :third_party
      expect(kase.requester_name).to eq kase.third_party_name
    end

    it "returns subject_name if not third_party request" do
      kase = create :offender_sar_case
      expect(kase.requester_name).to eq kase.subject_name
    end
  end

  describe "#requester_address" do
    it "returns third_party_address if third_party request" do
      kase = create :offender_sar_case, :third_party
      expect(kase.requester_address).to eq kase.third_party_address
    end

    it "returns subject_address if not third_party request" do
      kase = create :offender_sar_case
      expect(kase.requester_address).to eq kase.subject_address
    end
  end

  describe "#recipient_name" do
    it "returns third_party_name when subject not recipient" do
      kase = create :offender_sar_case, :third_party
      expect(kase.recipient_name).not_to eq kase.subject_name
      expect(kase.recipient_name).to eq kase.third_party_name
    end

    it "returns subject_name if subject is recipient" do
      kase = create :offender_sar_case
      expect(kase.recipient_name).not_to eq kase.third_party_name
      expect(kase.recipient_name).to eq kase.subject_name
    end

    it "returns nothing if third party and no name supplied" do
      kase = create :offender_sar_case, :third_party, third_party_name: ""

      expect(kase.recipient_name).to eq ""
    end
  end

  describe "#recipient_address" do
    it "returns third_party_address if subject not recipient" do
      kase = create :offender_sar_case, recipient: "requester_recipient"
      expect(kase.recipient_address).to eq kase.third_party_address
    end

    it "returns subject_address if if subject is recipient" do
      kase = create :offender_sar_case, recipient: "subject_recipient"
      expect(kase.recipient_address).to eq kase.subject_address
    end
  end

  describe "papertrail versioning", versioning: true do
    let(:kase) do
      create :offender_sar_case,
             name: "aaa",
             email: "aa@moj.com",
             received_date: Time.zone.today,
             subject_full_name: "subject A"
    end

    before do
      kase.update! name: "bbb",
                   email: "bb@moj.com",
                   received_date: 1.day.ago,
                   subject_full_name: "subject B"
    end

    it "can reconsititue a record from a version (except for received_date)" do
      original_kase = kase.versions.last.reify
      expect(original_kase.email).to eq "aa@moj.com"
      expect(kase.subject_full_name).to eq "subject B"
      expect(original_kase.subject_full_name).to eq "subject A"
    end

    it "reconstitutes the received date properly" do
      original_kase = kase.versions.last.reify
      expect(original_kase.received_date).to eq Time.zone.today
    end
  end

  describe "use_subject_as_requester callback" do
    context "when creating" do
      it "does not change the requester when present" do
        offender_sar_case = create :offender_sar_case, name: "Bob", subject_full_name: "Doug"
        expect(offender_sar_case.reload.name).to eq "Bob"
      end

      it "uses the subject as the requester if not present on update" do
        offender_sar_case = create :offender_sar_case, name: "", subject_full_name: "Doug"
        expect(offender_sar_case.reload.name).to eq "Doug"
      end
    end

    context "when updating" do
      it "does not change the requester when present" do
        offender_sar_case = create :offender_sar_case
        offender_sar_case.update! name: "Bob", subject_full_name: "Doug"
        expect(offender_sar_case.name).to eq "Bob"
      end

      it "uses the subject as the requester if not present on update" do
        offender_sar_case = create :offender_sar_case
        offender_sar_case.update! name: "", subject_full_name: "Doug"
        expect(offender_sar_case.name).to eq "Doug"
      end
    end
  end

  describe "#requires_flag_for_disclosure_specialists?" do
    it "returns true" do
      kase = create :offender_sar_case
      expect(kase.requires_flag_for_disclosure_specialists?).to be true
    end
  end

  describe ".searchable_fields_and_ranks" do
    it "includes subject full name" do
      expect(described_class.searchable_fields_and_ranks).to include({
        subject_full_name: "A",
        case_reference_number: "B",
        date_of_birth: "B",
        name: "B",
        number: "B",
        other_subject_ids: "B",
        postal_address: "B",
        previous_case_numbers: "B",
        prison_number: "B",
        requester_reference: "B",
        subject: "B",
        subject_address: "B",
        subject_aliases: "B",
        third_party_company_name: "B",
        third_party_name: "B",
      })
    end
  end

  describe "#reassign_gov_uk_dates" do
    let(:kase) { build :offender_sar_case }

    it "only re-assigns Gov UK date fields that are unchanged" do
      original_dob = kase.date_of_birth
      kase.reassign_gov_uk_dates
      kase.save!

      expect(kase.date_of_birth).to eq original_dob
    end

    it "does not reassign changed Gov UK dates fields" do
      new_dob = Date.parse("1990-10-01")
      kase.date_of_birth = new_dob
      kase.reassign_gov_uk_dates
      kase.save!

      expect(kase.date_of_birth).to eq new_dob
    end
  end

  describe "#allow_waiting_for_data_state?" do
    it "is true when the current state is data_to_be_requested only" do
      kase = build_stubbed :offender_sar_case
      expect(kase.current_state).to eq "data_to_be_requested"
      expect(kase.allow_waiting_for_data_state?).to be true

      kase.current_state = "waiting_for_data"
      expect(kase.allow_waiting_for_data_state?).to be false
    end
  end

  describe "#page_count" do
    let(:kase) { build :offender_sar_case }

    it "no data request" do
      expect(kase.page_count).to eq 0
    end

    it "have data request but have not received anything yet" do
      DataRequest.new(
        offender_sar_case: kase,
        user: build_stubbed(:user),
        location: "X" * 500, # Max length
        request_type: "all_prison_records",
        date_requested: Date.current,
      )
      expect(kase.page_count).to eq 0
    end

    it "have data requests and have received 200 pages" do
      data_request = DataRequest.new(
        offender_sar_case: kase,
        user: build_stubbed(:user),
        location: "X" * 500, # Max length,
        cached_num_pages: 200,
        request_type: "all_prison_records",
        date_requested: Date.current,
      )
      data_request.save!
      expect(kase.page_count).to eq 200
    end
  end

  describe "#data_requests_completed" do
    let(:kase) { build :offender_sar_case }

    it "no data request" do
      expect(kase.data_requests_completed?).to eq false
    end

    it "have data request but have not received anything yet" do
      DataRequest.new(
        offender_sar_case: kase,
        user: build_stubbed(:user),
        location: "X" * 500, # Max length
        request_type: "all_prison_records",
      )
      expect(kase.data_requests_completed?).to eq false
    end

    it "have data requests but only received partial requests have been received" do
      DataRequest.new(
        offender_sar_case: kase,
        user: build_stubbed(:user),
        location: "test",
        request_type: "all_prison_records",
      )
      DataRequest.new(
        offender_sar_case: kase,
        user: build_stubbed(:user),
        location: "test1",
        cached_num_pages: 200,
        request_type: "probation_records",
        completed: true,
      )
      expect(kase.data_requests_completed?).to eq false
    end

    it "have data requests and all the data have beeen received" do
      DataRequest.new(
        offender_sar_case: kase,
        user: build_stubbed(:user),
        location: "test2",
        cached_num_pages: 200,
        request_type: "all_prison_records",
        completed: true,
        date_requested: Date.new(2020, 8, 15),
        cached_date_received: Date.new(2020, 8, 15),
      ).save!
      DataRequest.new(
        offender_sar_case: kase,
        user: build_stubbed(:user),
        location: "test3",
        cached_num_pages: 100,
        request_type: "nomis_records",
        completed: true,
        date_requested: Date.new(2020, 8, 15),
        cached_date_received: Date.new(2020, 8, 15),
      ).save!
      expect(kase.data_requests_completed?).to eq true
    end
  end

  describe "#ensure_third_party_states_consistent" do
    context "when a case is saved with third_party and third_party_recipient" do
      let(:offender_sar_case) do
        build(:offender_sar_case, :third_party,
              recipient: "third_party_recipient") # would fail validation
      end

      it "automatically sets recipient to requester" do
        expect(offender_sar_case).to be_valid
        offender_sar_case.save!

        expect(offender_sar_case.recipient).to eq "requester_recipient"
      end
    end
  end

  describe "#num_days_taken" do
    let(:closed_kase) { create :offender_sar_case, :closed }
    let(:kase) { create :offender_sar_case }

    it "is 1 when case is received today" do
      kase.received_date = Time.zone.today
      expect(kase.num_days_taken).to be 1
    end

    it "returns correct number of days for open case" do
      kase.received_date = 3.days.before(Time.zone.today)
      expect(kase.num_days_taken).to eq 4
    end

    it "returns correct number of days late for closed case" do
      closed_kase.received_date = 10.days.before(Time.zone.today)
      closed_kase.date_responded = Time.zone.yesterday
      expect(closed_kase.num_days_taken).to eq 10
    end
  end

  describe "#num_days_late" do
    let(:kase) { create :offender_sar_case }
    let(:closed_kase) { create :offender_sar_case, :closed }

    it "is nil when 0 days late" do
      kase.external_deadline = Time.zone.today
      expect(kase.num_days_late).to be nil
    end

    it "is nil when not yet late for open case" do
      kase.external_deadline = Time.zone.tomorrow
      expect(kase.num_days_late).to be nil
    end

    it "returns correct number of days late for open case" do
      kase.external_deadline = Time.zone.yesterday
      expect(kase.num_days_late).to eq 1
    end

    it "returns correct number of days late for closed case" do
      closed_kase.external_deadline = 3.days.before(Time.zone.today)
      closed_kase.date_responded = Time.zone.yesterday
      expect(closed_kase.num_days_late).to eq 2
    end
  end

  describe "#first_prison_number" do
    let(:kase) { create :offender_sar_case }

    context "when there is just one prison number" do
      it "returns the prison number" do
        expect(kase.first_prison_number).to eq "123465"
      end
    end

    context "when there is more than one prison number" do
      let(:kases) do
        [
          create(:offender_sar_case, prison_number: "A12345, B98765"),
          create(:offender_sar_case, prison_number: "  A12345  , B98765 "),
          create(:offender_sar_case, prison_number: "A12345 B98765"),
          create(:offender_sar_case, prison_number: "A12345, B98765 A234667"),
        ]
      end

      it "returns the first prison number" do
        kases.each do |kase|
          expect(kase.first_prison_number).to eq "A12345"
        end
      end
    end

    context "when prison number is nil" do
      let(:kase)  { create :offender_sar_case, prison_number: nil }

      it "returns an empty string" do
        expect(kase.first_prison_number).to eq ""
      end
    end

    context "when prison number is an empty string" do
      let(:kase)  { create :offender_sar_case, prison_number: "" }

      it "returns an empty string" do
        expect(kase.first_prison_number).to eq ""
      end
    end

    context "when prison number is lowercase" do
      let(:kase)  { create :offender_sar_case, prison_number: "a12345" }

      it "returns it in uppercase" do
        expect(kase.first_prison_number).to eq "A12345"
      end
    end
  end

  describe "#probation_area" do
    let(:kase) { create :offender_sar_case }

    context "when the area is nil" do
      let(:kase)  { create :offender_sar_case, probation_area: nil }

      it "returns an empty string" do
        expect(kase.probation_area).to be nil
      end
    end

    context "when the area is an empty string" do
      let(:kase)  { create :offender_sar_case, probation_area: "" }

      it "returns an empty string" do
        expect(kase.probation_area).to eq ""
      end
    end
  end

  describe "#number_of_days_for_vetting" do
    it "is nil if the vetting process has not started yet" do
      kase = create :offender_sar_case
      expect(kase.number_of_days_for_vetting).to be nil
    end

    it "returns correct number when the vetting process started but not ended yet" do
      kase = nil
      Timecop.freeze Time.zone.local(2020, 4, 9, 13, 48, 22) do
        kase = create :offender_sar_case, :vetting_in_progress
      end

      Timecop.freeze Time.zone.local(2020, 4, 20, 13, 48, 22) do
        expect(kase.current_state).to eq "vetting_in_progress"
        expect(kase.number_of_days_for_vetting).to be 6
      end
    end

    it "returns correct number when the vetting process has ended" do
      kase = nil
      Timecop.freeze Time.zone.local(2020, 4, 9, 13, 48, 22) do
        kase = create :offender_sar_case, :vetting_in_progress
      end

      Timecop.freeze Time.zone.local(2020, 4, 20, 13, 48, 22) do
        create :case_transition_ready_to_copy, case: kase
      end

      Timecop.freeze Time.zone.local(2020, 5, 2, 13, 48, 22) do
        create :case_transition_ready_to_dispatch, case: kase
        expect(kase.current_state).to eq "ready_to_dispatch"
        expect(kase.number_of_days_for_vetting).to be 6
      end
    end
  end

  describe "#user_dealing_with_vetting" do
    it "return user id" do
      kase = create :offender_sar_case, :vetting_in_progress
      expect(kase.user_dealing_with_vetting.id).to be kase.responding_team.users.first.id
    end
  end

  describe "#assign_vetter" do
    let(:responder) { find_or_create :responder }
    let(:responding_team) { responder.teams.first }

    it "sets responding user to expected" do
      kase = create :offender_sar_case, :vetting_in_progress
      expect {
        kase.assign_vetter(responder)
      }.to change(kase.responder_assignment, :user_id).to responder.id
    end
  end

  describe "#unassign_vetter" do
    let(:responder) { find_or_create :responder }
    let(:responding_team) { responder.teams.first }

    it "sets responding user to nil" do
      kase = create :offender_sar_case, :vetting_in_progress
      kase.assignments << Assignment.new(state: "pending", team_id: responding_team.id, role: "responding", user: responder, approved: false)
      expect {
        kase.unassign_vetter
      }.to change(kase.responder_assignment, :user_id).to nil
    end
  end

  describe "#partial flags" do
    it "errors when further_actions_required is true but is_partial_case" do
      kase = build_stubbed(:offender_sar_case, is_partial_case: false, further_actions_required: "yes")
      expect(kase).not_to be_valid
      expect(kase.errors[:is_partial_case]).to eq ["Cannot be marked if case is marked as SSCL managing case"]
    end

    it "validate values" do
      kase = build_stubbed(:offender_sar_case, is_partial_case: false, further_actions_required: "no")
      expect(kase).to be_valid

      kase = build_stubbed(:offender_sar_case, is_partial_case: true, further_actions_required: "yes")
      expect(kase).to be_valid

      kase = build_stubbed(:offender_sar_case, is_partial_case: true, further_actions_required: "no")
      expect(kase).to be_valid
    end
  end

  describe "#rejected?" do
    context "when case is unsaved" do
      context "when case is rejected" do
        it "returns true" do
          kase = build(:offender_sar_case, :rejected)
          expect(kase).to be_rejected
        end

        it "is not valid without flag_as_dps_missing_data" do
          kase = build_stubbed :offender_sar_case, :rejected, flag_as_dps_missing_data: nil

          expect(kase).not_to be_valid
          expect(kase.errors[:flag_as_dps_missing_data]).to eq(["cannot be blank"])
        end
      end

      context "when case is not rejected" do
        it "returns false" do
          kase = build(:offender_sar_case)
          expect(kase).not_to be_rejected
        end

        it "is valid without flag_as_dps_missing_data" do
          kase = build_stubbed :offender_sar_case, flag_as_dps_missing_data: nil

          expect(kase).to be_valid
          expect(kase.errors[:flag_as_dps_missing_data]).to be_empty
        end
      end
    end

    context "when case is rejected" do
      it "returns true" do
        kase = create(:offender_sar_case, :rejected)
        expect(kase).to be_rejected
      end
    end

    context "when case is rejected and closed" do
      it "returns true" do
        kase = create(:offender_sar_case, :rejected)
        kase.close(build_stubbed(:user))
        expect(kase).to be_rejected
      end
    end

    context "when case is not rejected" do
      it "returns false" do
        kase = create(:offender_sar_case)
        expect(kase).not_to be_rejected
      end
    end
  end
end
