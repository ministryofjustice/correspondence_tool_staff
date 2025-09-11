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

describe Case::SAR::OffenderComplaint do
  context "when factory should be valid" do
    it "is valid" do
      kase = build_stubbed :offender_sar_complaint

      expect(kase).to be_valid
    end
  end

  describe "predicate methods" do
    describe "#type_of_offender_sar?" do
      it "is a sort of offender_sar" do
        kase = build_stubbed :offender_sar_complaint
        expect(kase.type_of_offender_sar?).to be true
      end
    end

    describe "#offender_sar?" do
      it "is offender_sar standard" do
        kase = build_stubbed :offender_sar_complaint
        expect(kase.offender_sar?).to be false
      end
    end

    describe "#offender_sar_complaint?" do
      it "is not an offender_sar complaint" do
        kase = build_stubbed :offender_sar_complaint
        expect(kase.offender_sar_complaint?).to be true
      end
    end
  end

  context "when validates that SAR-specific fields are not blank" do
    it "is not valid" do
      kase = build_stubbed :offender_sar_complaint, subject_full_name: nil, subject_type: nil, third_party: nil, flag_as_high_profile: nil, flag_as_dps_missing_data: nil

      expect(kase).not_to be_valid
      expect(kase.errors[:subject_full_name]).to eq(["cannot be blank"])
      expect(kase.errors[:third_party]).to eq(["cannot be blank"])
      expect(kase.errors[:flag_as_high_profile]).to eq(["cannot be blank"])
      expect(kase.errors[:flag_as_dps_missing_data]).to be_empty
    end
  end

  describe "#complaint_type" do
    context "when validates that complaint type is not blank" do
      it "errors" do
        kase = build_stubbed(:offender_sar_complaint, complaint_type: nil)
        expect(kase).not_to be_valid
        expect(kase.errors[:complaint_type]).to eq ["cannot be blank"]
      end
    end

    context "with valid values" do
      it "does not error" do
        expect(build_stubbed(:offender_sar_complaint, complaint_type: "standard_complaint")).to be_valid
        expect(build_stubbed(:offender_sar_complaint, complaint_type: "ico_complaint")).to be_valid
        expect(build_stubbed(:offender_sar_complaint, complaint_type: "litigation_complaint")).to be_valid
      end
    end

    context "with invalid value" do
      it "errors" do
        expect {
          build_stubbed(:offender_sar_complaint, complaint_type: "wibble")
        }.to raise_error ArgumentError
      end
    end
  end

  describe "#priority" do
    context "when validates that priority is not blank" do
      it "errors" do
        kase = build_stubbed(:offender_sar_complaint, priority: nil)
        expect(kase).not_to be_valid
        expect(kase.errors[:priority]).to eq ["cannot be blank"]
      end
    end

    context "with valid values" do
      it "does not error" do
        expect(build_stubbed(:offender_sar_complaint, priority: "normal")).to be_valid
        expect(build_stubbed(:offender_sar_complaint, priority: "high")).to be_valid
      end
    end

    context "with invalid value" do
      it "errors" do
        expect {
          build_stubbed(:offender_sar_complaint, priority: "enormous")
        }.to raise_error ArgumentError
      end
    end
  end

  describe "#normal_priority?" do
    it "delegates to normal?" do
      kase = build(:offender_sar_complaint, priority: "normal")
      expect(kase.normal_priority?).to be true
      kase.high!
      expect(kase.normal_priority?).to be false
    end
  end

  describe "#high_priority?" do
    it "delegates to high?" do
      kase = build(:offender_sar_complaint, priority: "high")
      expect(kase.high_priority?).to be true
      kase.normal!
      expect(kase.high_priority?).to be false
    end
  end

  describe "#complaint_subtype" do
    context "when validates that complaint_subtype is not blank" do
      it "errors" do
        kase = build_stubbed(:offender_sar_complaint, complaint_subtype: nil)
        expect(kase).not_to be_valid
        expect(kase.errors[:complaint_subtype]).to eq ["cannot be blank"]
      end
    end

    context "with valid values" do
      it "does not error" do
        expect(build_stubbed(:offender_sar_complaint, complaint_subtype: "missing_data")).to be_valid
        expect(build_stubbed(:offender_sar_complaint, complaint_subtype: "inaccurate_data")).to be_valid
        expect(build_stubbed(:offender_sar_complaint, complaint_subtype: "redacted_data")).to be_valid
        expect(build_stubbed(:offender_sar_complaint, complaint_subtype: "timeliness")).to be_valid
      end
    end

    context "with invalid value" do
      it "errors" do
        expect {
          build_stubbed(:offender_sar_complaint, complaint_subtype: "purple")
        }.to raise_error ArgumentError
      end
    end
  end

  describe "#subject_type" do
    context "with valid values" do
      it "does not error" do
        expect(build_stubbed(:offender_sar_complaint, subject_type: "detainee")).to be_valid
        expect(build_stubbed(:offender_sar_complaint, subject_type: "ex_detainee")).to be_valid
        expect(build_stubbed(:offender_sar_complaint, subject_type: "ex_offender")).to be_valid
        expect(build_stubbed(:offender_sar_complaint, subject_type: "ex_probation_service_user")).to be_valid
        expect(build_stubbed(:offender_sar_complaint, subject_type: "offender")).to be_valid
        expect(build_stubbed(:offender_sar_complaint, subject_type: "probation_service_user")).to be_valid
      end
    end

    context "with invalid value" do
      it "errors" do
        expect {
          build_stubbed(:offender_sar_complaint, subject_type: "plumber")
        }.to raise_error ArgumentError
      end
    end

    context "with nil" do
      it "errors" do
        kase = build_stubbed(:offender_sar_complaint, subject_type: nil)
        expect(kase).not_to be_valid
        expect(kase.errors[:subject_type]).to eq ["cannot be blank"]
      end
    end
  end

  describe "#recipient" do
    context "with valid values" do
      it "does not error" do
        expect(build_stubbed(:offender_sar_complaint, recipient: "subject_recipient")).to be_valid
        expect(build_stubbed(:offender_sar_complaint, recipient: "requester_recipient")).to be_valid
        expect(build_stubbed(:offender_sar_complaint,
                             recipient: "third_party_recipient",
                             third_party: false,
                             third_party_name: "test",
                             third_party_relationship: "test")).to be_valid
      end
    end

    context "with invalid value" do
      it "errors" do
        expect {
          build_stubbed(:offender_sar_complaint, recipient: "user")
        }.to raise_error ArgumentError
      end
    end

    context "with nil" do
      it "errors" do
        kase = build_stubbed(:offender_sar_complaint, recipient: nil)
        expect(kase).not_to be_valid
        expect(kase.errors[:recipient]).to eq ["cannot be blank"]
      end
    end
  end

  describe "#postal_address" do
    context "with valid values" do
      it "validates when address is set" do
        kase = build_stubbed(:offender_sar_complaint, :third_party, postal_address: "22 Acacia Avenue")
        expect(kase).to be_valid
      end
    end

    context "with invalid values" do
      it "validates presence of postal address when recipient is third party" do
        kase = build_stubbed :offender_sar_complaint, :third_party, postal_address: ""
        expect(kase).not_to be_valid
        expect(kase.errors[:postal_address]).to eq ["cannot be blank"]
      end
    end
  end

  describe "#date_of_birth" do
    context "with valid values" do
      it "validates date of birth" do
        kase = build_stubbed :offender_sar_complaint

        expect(kase).to validate_presence_of(:date_of_birth)
        expect(kase).to allow_values("01-01-1967").for(:date_of_birth)
      end
    end

    context "with invalid value" do
      it "errors" do
        expect {
          build_stubbed(:offender_sar_complaint, date_of_birth: "wibble")
        }.to raise_error ArgumentError
      end
    end

    context "when date of birth cannot be in future" do
      it "errors" do
        kase = build_stubbed(:offender_sar_complaint, date_of_birth: 1.day.from_now)
        expect(kase).not_to be_valid
        expect(kase.errors[:date_of_birth]).to eq ["cannot be in the future."]
      end
    end

    context "with nil" do
      it "errors" do
        kase = build_stubbed(:offender_sar_complaint, date_of_birth: nil)
        expect(kase).not_to be_valid
        expect(kase.errors[:date_of_birth]).to eq ["cannot be blank"]
      end
    end
  end

  describe "#received_date" do
    context "with valid values" do
      it "validates received date" do
        kase = build_stubbed :offender_sar_complaint
        test_date = 4.business_days.ago.strftime("%d-%m-%Y")

        expect(kase).to validate_presence_of(:received_date)
        expect(kase).to allow_values(test_date).for(:received_date)
      end
    end

    context "with invalid value" do
      it "errors" do
        expect {
          build_stubbed(:offender_sar_complaint, received_date: "wibble")
        }.to raise_error ArgumentError
      end
    end

    context "when received date cannot be in future" do
      it "errors" do
        kase = build_stubbed(:offender_sar_complaint, received_date: 1.day.from_now)
        expect(kase).not_to be_valid
        expect(kase.errors[:received_date]).to eq ["cannot be in the future."]
      end
    end
  end

  describe "#request_dated" do
    context "with invalid value" do
      it "errors" do
        expect {
          build_stubbed(:offender_sar_complaint, request_dated: "wibble")
        }.to raise_error ArgumentError
      end
    end

    context "when request_dated date cannot be in future" do
      it "errors" do
        kase = build_stubbed(:offender_sar_complaint, request_dated: 1.day.from_now)
        expect(kase).not_to be_valid
        expect(kase.errors[:request_dated]).to eq ["cannot be in the future."]
      end
    end
  end

  describe "number_exempt_pages" do
    context "with invalid values" do
      it "errors when float is used" do
        kase = build_stubbed(:offender_sar_complaint, number_exempt_pages: -562)
        expect(kase).not_to be_valid
        expect(kase.errors[:number_exempt_pages]).to eq ["must be a positive whole number"]
      end
    end

    context "with valid values" do
      it "is valid when string represents a positive whole number" do
        kase = build_stubbed(:offender_sar_complaint, number_exempt_pages: 4835)
        expect(kase).to be_valid
      end
    end
  end

  describe "number_final_pages" do
    context "with invalid values" do
      it "errors when string represents a negative whole number" do
        kase = build_stubbed(:offender_sar_complaint, number_final_pages: -562)
        expect(kase).not_to be_valid
        expect(kase.errors[:number_final_pages]).to eq ["must be a positive whole number"]
      end
    end

    context "with valid values" do
      it "is valid when string represents a positive whole number" do
        kase = build_stubbed(:offender_sar_complaint, number_final_pages: 4835)
        expect(kase).to be_valid
      end
    end
  end

  describe "third party details" do
    describe "third_party_names" do
      it "validates third party names when third party is true" do
        kase = build_stubbed :offender_sar_complaint, :third_party, third_party_name: "", third_party_company_name: ""
        expect(kase).not_to be_valid
        expect(kase.errors[:third_party_name]).to eq ["cannot be blank if company name not given"]
        expect(kase.errors[:third_party_company_name]).to eq ["cannot be blank if representative name not given"]
      end

      it "validates third party names when recipient is third party" do
        kase = build_stubbed :offender_sar_complaint, third_party: false, third_party_name: "",
                                                      third_party_company_name: "", recipient: "third_party_recipient"
        expect(kase).not_to be_valid
        expect(kase.errors[:third_party_name]).to eq ["cannot be blank if company name not given"]
        expect(kase.errors[:third_party_company_name]).to eq ["cannot be blank if representative name not given"]
      end

      it "does not validate third_party names when ecipient is not third party too" do
        kase = build_stubbed :offender_sar_complaint, third_party: false, third_party_name: "",
                                                      third_party_company_name: "", recipient: "subject_recipient"
        expect(kase).to be_valid
      end
    end

    describe "third party relationship" do
      it "must be present when thrid party is true" do
        kase = build_stubbed :offender_sar_complaint, third_party: true, third_party_relationship: ""
        expect(kase).not_to be_valid
        expect(kase.errors[:third_party_relationship]).to eq ["cannot be blank"]
      end

      it "must be present when third party is false but recipient is third party" do
        kase = build_stubbed :offender_sar_complaint, third_party: false, third_party_relationship: "",
                                                      recipient: "third_party_recipient"
        expect(kase).not_to be_valid
        expect(kase.errors[:third_party_relationship]).to eq ["cannot be blank"]
      end

      it "does not validates presence of third party relationship when recipient is not third party" do
        kase = build_stubbed :offender_sar_complaint, third_party: false, third_party_relationship: "",
                                                      recipient: "subject_recipient"
        expect(kase).to be_valid
      end
    end
  end

  describe "#subject" do
    it "is the same as subject full name" do
      kase = create :offender_sar_complaint
      expect(kase.subject).to eq kase.subject_full_name
      kase.update!(subject_full_name: "Bob Hope")
      expect(kase.subject).to eq "Bob Hope"
    end
  end

  describe "#subject_name" do
    it "is the same as subject_full_name" do
      kase = create :offender_sar_complaint
      expect(kase.subject_name).to eq kase.subject_full_name
      kase.update!(subject_full_name: "Bob Hope")
      expect(kase.subject_name).to eq "Bob Hope"
    end
  end

  describe "#subject_address" do
    it "returns a dummy string for now" do
      kase = create :offender_sar_complaint
      expect(kase.subject_address).to eq "22 Sample Address, Test Lane, Testingington, TE57ST"
    end

    it "validates presence of subject address" do
      kase = build_stubbed :offender_sar_complaint, subject_address: ""
      expect(kase).not_to be_valid
      expect(kase.errors[:subject_address]).to eq ["cannot be blank"]
    end
  end

  describe "#third_party_address" do
    it "wraps the postal_address field" do
      kase = create :offender_sar_complaint
      expect(kase.third_party_address).to eq kase.postal_address
      kase.update!(postal_address: "11 The Road")
      expect(kase.third_party_address).to eq "11 The Road"
    end
  end

  describe "#requester_name" do
    it "returns third_party_name if third_party request" do
      kase = create :offender_sar_complaint, :third_party
      expect(kase.requester_name).to eq kase.third_party_name
    end

    it "returns subject_name if not third_party request" do
      kase = create :offender_sar_complaint
      expect(kase.requester_name).to eq kase.subject_name
    end
  end

  describe "#requester_address" do
    it "returns third_party_address if third_party request" do
      kase = create :offender_sar_complaint, :third_party
      expect(kase.requester_address).to eq kase.third_party_address
    end

    it "returns subject_address if not third_party request" do
      kase = create :offender_sar_complaint
      expect(kase.requester_address).to eq kase.subject_address
    end
  end

  describe "#recipient_name" do
    it "returns third_party_name when subject not recipient" do
      kase = create :offender_sar_complaint, :third_party
      expect(kase.recipient_name).not_to eq kase.subject_name
      expect(kase.recipient_name).to eq kase.third_party_name
    end

    it "returns subject_name if subject is recipient" do
      kase = create :offender_sar_complaint
      expect(kase.recipient_name).not_to eq kase.third_party_name
      expect(kase.recipient_name).to eq kase.subject_name
    end

    it "returns nothing if third party and no name supplied" do
      kase = create :offender_sar_complaint, :third_party, third_party_name: ""

      expect(kase.recipient_name).to eq ""
    end
  end

  describe "#recipient_address" do
    it "returns third_party_address if subject not recipient" do
      kase = create :offender_sar_complaint, recipient: "requester_recipient"
      expect(kase.recipient_address).to eq kase.third_party_address
    end

    it "returns subject_address if if subject is recipient" do
      kase = create :offender_sar_complaint, recipient: "subject_recipient"
      expect(kase.recipient_address).to eq kase.subject_address
    end
  end

  describe "papertrail versioning", versioning: true do
    let(:kase) do
      create :offender_sar_complaint,
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
        offender_sar_complaint = create :offender_sar_complaint, name: "Bob", subject_full_name: "Doug"
        expect(offender_sar_complaint.reload.name).to eq "Bob"
      end

      it "uses the subject as the requester if not present on update" do
        offender_sar_complaint = create :offender_sar_complaint, name: "", subject_full_name: "Doug"
        expect(offender_sar_complaint.reload.name).to eq "Doug"
      end
    end

    context "when updating" do
      it "does not change the requester when present" do
        offender_sar_complaint = create :offender_sar_complaint
        offender_sar_complaint.update! name: "Bob", subject_full_name: "Doug"
        expect(offender_sar_complaint.name).to eq "Bob"
      end

      it "uses the subject as the requester if not present on update" do
        offender_sar_complaint = create :offender_sar_complaint
        offender_sar_complaint.update! name: "", subject_full_name: "Doug"
        expect(offender_sar_complaint.name).to eq "Doug"
      end
    end
  end

  describe "#requires_flag_for_disclosure_specialists?" do
    it "returns true" do
      kase = create :offender_sar_complaint
      expect(kase.requires_flag_for_disclosure_specialists?).to be true
    end
  end

  describe ".searchable_fields_and_ranks" do
    it "includes subject full name" do
      expect(Case::SAR::Offender.searchable_fields_and_ranks).to include({
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
    let(:kase) { build :offender_sar_complaint }

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
      kase = build_stubbed :offender_sar_complaint

      expect(kase.current_state).to eq "to_be_assessed"
      expect(kase.allow_waiting_for_data_state?).to be false

      kase.current_state = "data_to_be_requested"
      expect(kase.allow_waiting_for_data_state?).to be true

      kase.current_state = "waiting_for_data"
      expect(kase.allow_waiting_for_data_state?).to be false
    end
  end

  describe "ico details" do
    describe "#ico_contact_name" do
      it "must be present when ico is true" do
        kase = build_stubbed :offender_sar_complaint, complaint_type: "ico_complaint", ico_contact_name: ""
        expect(kase).not_to be_valid
        expect(kase.errors[:ico_contact_name]).to eq ["cannot be blank"]
      end

      it "is not required when litigation or standard complaint" do
        kase1 = build_stubbed :offender_sar_complaint, complaint_type: "standard_complaint", ico_contact_name: ""
        kase2 = build_stubbed :offender_sar_complaint, complaint_type: "litigation_complaint", ico_contact_name: ""
        expect(kase1).to be_valid
        expect(kase2).to be_valid
      end
    end
  end

  describe "#page_count" do
    let(:kase) { build :offender_sar_complaint }

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
    let(:kase) { build :offender_sar_complaint }

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
      let(:offender_sar_complaint) do
        build(:offender_sar_complaint, :third_party,
              recipient: "third_party_recipient") # would fail validation
      end

      it "automatically sets recipient to requester" do
        expect(offender_sar_complaint).to be_valid
        offender_sar_complaint.save!

        expect(offender_sar_complaint.recipient).to eq "requester_recipient"
      end
    end
  end

  describe "original_case association" do
    it {
      expect(described_class.new).to have_one(:original_case)
                  .through(:original_case_link)
                  .source(:linked_case)
    }

    it "Validates that the complaint can link to a offender sar case as original case" do
      linked_case = create(:offender_sar_case, :closed)
      complaint = build_stubbed(:offender_sar_complaint, original_case: linked_case)
      expect(complaint).to be_valid
      expect(complaint.original_case).to eq linked_case
    end

    it "validates that the case can be associated as an original case" do
      linked_case = create(:offender_sar_complaint, :closed)
      complaint = build_stubbed(:offender_sar_complaint, original_case: linked_case)
      expect(complaint).not_to be_valid
      expect(complaint.errors[:original_case])
        .to eq ["Original case must be Offender SAR"]
    end

    it "validates that a case isn't both original and related" do
      offender_sar = create(:offender_sar_case)
      complaint = build_stubbed(:offender_sar_complaint, original_case: offender_sar, related_cases: [offender_sar])
      expect(complaint).not_to be_valid
      expect(complaint.errors[:linked_cases])
        .to eq ["already linked as the original case"]
    end

    it "validates that original case is present" do
      complaint = create(:offender_sar_complaint)
      complaint.original_case = nil
      complaint.valid?
      expect(complaint.errors[:original_case]).to eq ["cannot be blank"]
    end
  end

  describe "original_case_link association" do
    it {
      expect(described_class.new).to have_one(:original_case_link)
                  .class_name("LinkedCase")
                  .with_foreign_key("case_id")
    }
  end

  describe "#original_case_id" do
    it "finds case and assigns to original_case" do
      offender_sar = create(:offender_sar_case)
      complaint = build_stubbed(:offender_sar_complaint, original_case: nil)
      complaint.original_case_id = offender_sar.id
      expect(complaint).to be_valid
      expect(complaint.original_case).to eq offender_sar
    end
  end

  describe "case_links association" do
    it "validates that the offender sar cannot be in related cases" do
      offender_sar = create(:offender_sar_case)
      complaint = build_stubbed(:offender_sar_complaint, related_cases: [offender_sar])
      complaint.valid?
      expect(complaint).not_to be_valid
      expect(complaint.errors[:related_cases])
      .to eq ["cannot link a Complaint case to a Offender SAR as a related case"]
    end
  end

  describe "external_deadline attribute" do
    it "is assignable by year, month and day" do
      offender_sar = create(:offender_sar_case)
      complaint = build_stubbed(:offender_sar_complaint, original_case: offender_sar)
      complaint.external_deadline_yyyy = "2018"
      complaint.external_deadline_mm   = "1"
      complaint.external_deadline_dd   = "12"
      expect(complaint.external_deadline).to eq Date.new(2018, 1, 12)
    end

    it "cannot be before than received_date" do
      offender_sar = create(:offender_sar_case)
      complaint = create(:offender_sar_complaint,
                         original_case: offender_sar,
                         received_date: Time.zone.today - 10)
      complaint.valid?
      expect(complaint).to be_valid
      complaint.external_deadline = complaint.received_date - 1.day
      complaint.valid?
      expect(complaint.errors[:external_deadline])
        .to eq ["cannot be before date received"]
    end

    it "cannot be past day for new record" do
      offender_sar = create(:offender_sar_case)
      complaint = build(:offender_sar_complaint,
                        original_case: offender_sar,
                        received_date: Time.zone.today - 10.days,
                        external_deadline: Time.zone.today - 1.day)
      complaint.valid?
      expect(complaint).not_to be_valid
      expect(complaint.errors[:external_deadline])
        .to eq ["cannot be in the past"]
    end
  end

  describe "#case number" do
    it "'Q' + original_case.number if one complaint" do
      complaint = create(:offender_sar_complaint)
      expect(complaint.number).to eq "Q#{complaint.original_case.number}"
    end

    it "'Q' + original_case.number + '-' + sequence number if multi-complaints" do
      complaint = create(:offender_sar_complaint)
      complaint1 = create(:offender_sar_complaint, original_case: complaint.original_case)
      expect(complaint1.number).to eq "Q#{complaint.original_case.number}-001"
    end

    it "'DQ' + original_case.number" do
      test_cases = {
        "D123456" => "DQ123456",
        "DQ123456" => "DQ123456",
        "DR123456" => "DQ123456",
        "123456" => "Q123456",
        nil => nil,
        "  " => "  ",
      }

      complaint = create(:offender_sar_complaint)

      test_cases.each do |input, output|
        complaint.number = input
        expect(complaint.send(:case_number_with_new_prefix, input)).to eq output
      end
    end
  end

  describe "#has_costs?" do
    it "has no costs" do
      complaint = create(:offender_sar_complaint)
      expect(complaint.has_costs?).to eq false
    end

    it "has settlement cost" do
      complaint = create(:offender_sar_complaint, settlement_cost: 123)
      expect(complaint.has_costs?).to eq true
    end

    it "has total cost" do
      complaint = create(:offender_sar_complaint, total_cost: 456)
      expect(complaint.has_costs?).to eq true
    end

    it "has both costs" do
      complaint = create(:offender_sar_complaint, settlement_cost: 123.12, total_cost: 456.55)
      expect(complaint.has_costs?).to eq true
    end
  end
end
