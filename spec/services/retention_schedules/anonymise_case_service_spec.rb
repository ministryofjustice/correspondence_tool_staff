require "rails_helper"

describe RetentionSchedules::AnonymiseCaseService, versioning: true do
  let(:manager)         { find_or_create :branston_user }
  let(:managing_team)   { create :managing_team, managers: [manager] }

  let!(:offender_sar_case) do
    case_with_retention_schedule(
      case_type: :offender_sar_case,
      case_state: :closed,
      rs_state: :to_be_anonymised,
      date: Time.zone.today - 4.months,
    )
  end

  let!(:third_party_offender_sar_case) do
    case_with_retention_schedule(
      case_type: :offender_sar_case,
      case_state: :closed,
      rs_state: :to_be_anonymised,
      third_party: true,
      date: Time.zone.today - 4.months,
    )
  end

  let!(:case_with_no_relations) do
    case_with_retention_schedule(
      case_type: :offender_sar_case,
      case_state: :closed,
      rs_state: :to_be_anonymised,
      date: Time.zone.today - 4.months,
    )
  end

  let!(:offender_sar_complaint) do
    case_with_retention_schedule(
      case_type: :offender_sar_complaint,
      case_state: :closed,
      rs_state: :to_be_anonymised,
      date: Time.zone.today - 4.months,
    )
  end

  let(:service) do
    described_class.new(kase: offender_sar_case)
  end

  let(:service_two) do
    described_class.new(kase: offender_sar_complaint)
  end

  let(:service_three) do
    described_class.new(kase: case_with_no_relations)
  end

  let(:service_third_party) do
    described_class.new(kase: third_party_offender_sar_case)
  end

  let(:expected_off_sar_anon_values) do
    {
      case_reference_number: "123456",
      date_of_birth: Date.new(0o1, 0o1, 0o001),
      email: "anon.email@cms-gdpr.justice.gov.uk",
      message: "Information has been anonymised",
      name: "XXXX XXXX",
      other_subject_ids: "YY0123456789X",
      postal_address: "Anon address",
      previous_case_numbers: "XXXXXXXX",
      prison_number: "123456",
      # probation_area: "Smallville",
      requester_reference: "XXXXXX",
      subject: "XXXX XXXX",
      subject_address: "Anon location",
      subject_aliases: "Anon alias",
      subject_full_name: "XXXX XXXX",
      third_party_company_name: nil,
      third_party_name: nil,
    }
  end

  let(:expected_third_party_off_sar_anon_values) do
    {
      case_reference_number: "123456",
      date_of_birth: Date.new(0o1, 0o1, 0o001),
      email: "anon.email@cms-gdpr.justice.gov.uk",
      message: "Information has been anonymised",
      name: "XXXX XXXX",
      other_subject_ids: "YY0123456789X",
      postal_address: "Anon address",
      previous_case_numbers: "XXXXXXXX",
      prison_number: "123456",
      # probation_area: "Smallville",
      requester_reference: "XXXXXX",
      subject: "XXXX XXXX",
      subject_address: "Anon location",
      subject_aliases: "Anon alias",
      subject_full_name: "XXXX XXXX",
      third_party_name: "Anon requester",
      third_party_relationship: "Anon relationship",
    }
  end

  let(:expected_off_sar_complaint_anon_values) do
    expected_off_sar_anon_values.merge(
      {
        gld_contact_email: "anon.email@cms-gdpr.justice.gov.uk",
        gld_contact_name: "XXXX XXXX",
        gld_contact_phone: "XXXX XXXX",
        gld_reference: "XXXX XXXX",
        ico_contact_email: "anon.email@cms-gdpr.justice.gov.uk",
        ico_contact_name: "XXXX XXXX",
        ico_contact_phone: "XXXX XXXX",
        ico_reference: "XXXX XXXX",
      },
    )
  end

  describe "#call" do
    before do
      5.times do |i|
        offender_sar_case.state_machine.add_note_to_case!(
          acting_user: manager,
          acting_team: manager.case_team(offender_sar_case),
          message: "Note on case #{i}",
        )

        offender_sar_complaint.state_machine.add_note_to_case!(
          acting_user: manager,
          acting_team: manager.case_team(offender_sar_complaint),
          message: "Note on case #{i}",
        )
      end

      10.times do |i|
        offender_sar_case.data_requests << DataRequest.new(
          user: manager,
          location: "X" * 500, # Max length
          request_type: "all_prison_records",
          request_type_note: "this is a data request note #{i}",
          date_requested: Date.current,
        )

        offender_sar_complaint.data_requests << DataRequest.new(
          user: manager,
          location: "X" * 500, # Max length
          request_type: "all_prison_records",
          request_type_note: "this is a data request note #{i}",
          date_requested: Date.current,
        )
      end

      # check setup
      # rubocop:disable RSpec/ExpectInHook
      expect(offender_sar_case.versions.count).to be > 0
      expect(offender_sar_case.retention_schedule.present?).to be(true)
      expect(offender_sar_complaint.versions.count).to be > 0
      expect(offender_sar_case.data_requests.count).to be > 0
      expect(offender_sar_complaint.data_requests.count).to be > 0
      # rubocop:enable RSpec/ExpectInHook

      service.call
      service_two.call
      service_three.call
      service_third_party.call

      offender_sar_case.reload
      offender_sar_complaint.reload
    end

    it "can anonymise the key fields of a Offender SAR case" do
      expected_off_sar_anon_values.each do |kase_attribute_name, value|
        expect(offender_sar_case.send(kase_attribute_name)).to eq(value), "Case attribute name #{kase_attribute_name} - Model value: #{offender_sar_case.send(kase_attribute_name)}"
      end
    end

    it "can anonymise the key fields of a third party Offender SAR case" do
      expected_third_party_off_sar_anon_values.each do |kase_attribute_name, value|
        expect(third_party_offender_sar_case.send(kase_attribute_name)).to eq(value)
      end
    end

    it "can anonymise the key fields of a Offender SAR Complaint case" do
      expected_off_sar_complaint_anon_values.each do |kase_attribute_name, value|
        expect(offender_sar_complaint.send(kase_attribute_name)).to eq(value)
      end
    end

    it "can anonymise the key fields of a plain case without many relations" do
      expected_off_sar_anon_values.each do |kase_attribute_name, value|
        expect(case_with_no_relations.send(kase_attribute_name)).to eq(value)
      end
    end

    it "can anonymise the notes on a case" do
      sar_notes = offender_sar_case
                  .transitions
                  .where(event: "add_note_to_case")
                  .map(&:message)

      complaint_notes = offender_sar_case
                  .transitions
                  .where(event: "add_note_to_case")
                  .map(&:message)

      notes = sar_notes + complaint_notes

      expect(notes).to all eq("Note details have been anonymised")
    end

    it "can destroy the papertrail versions of a case" do
      expect(offender_sar_case.versions.empty?).to be true
      expect(offender_sar_complaint.versions.empty?).to be true
    end

    it 'can anonymise the data request "other details" of a case' do
      offender_sar_case.data_requests.each do |data_request|
        expect(data_request.request_type_note).to eq("Information has been anonymised")
      end

      offender_sar_complaint.data_requests.each do |data_request|
        expect(data_request.request_type_note).to eq("Information has been anonymised")
      end
    end

    it "updates the cases retention schedule to anonymised" do
      retention_schedule = offender_sar_case.retention_schedule
      expect(retention_schedule.aasm.current_state).to eq(:anonymised)
      expect(retention_schedule.erasure_date).to eq(Time.zone.today)
    end
  end

  describe "error states" do
    let(:open_case) do
      instance_double(
        Case::SAR::Offender,
        type_of_offender_sar?: true,
        closed?: false,
      )
    end

    let(:no_rs_case) do
      instance_double(
        Case::SAR::Offender,
        type_of_offender_sar?: true,
        closed?: true,
        retention_schedule: instance_double(
          RetentionSchedule,
          blank?: true,
        ),
      )
    end

    let(:wrong_rs_state) do
      instance_double(
        Case::SAR::Offender,
        type_of_offender_sar?: true,
        closed?: true,
        retention_schedule: instance_double(
          RetentionSchedule,
          blank?: false,
          to_be_anonymised?: false,
        ),
      )
    end

    let(:wrong_case_type) do
      instance_double(
        Case::Base,
        type_of_offender_sar?: false,
        retention_schedule: instance_double(
          RetentionSchedule,
          blank?: false,
        ),
      )
    end

    it "will raise an error if case is not closed" do
      expect {
        service = described_class.new(
          kase: open_case,
        )
        service.call
      }.to raise_error RetentionSchedules::CaseNotClosedError
    end

    it "will raise an error if case has no retention schedule" do
      expect {
        service = described_class.new(
          kase: no_rs_case,
        )
        service.call
      }.to raise_error RetentionSchedules::NoRetentionScheduleError
    end

    it "will raise and error if a case is not an Offender SAR or an Offender SAR complaint" do
      expect {
        service = described_class.new(
          kase: wrong_case_type,
        )
        service.call
      }.to raise_error RetentionSchedules::WrongCaseTypeError
    end

    it "will raise an error if the case retention schedule does not have a state of :to_be_anonymised" do
      expect {
        service = described_class.new(
          kase: wrong_rs_state,
        )
        service.call
      }.to raise_error RetentionSchedules::UnactionableStateError
    end
  end

  def case_with_retention_schedule(case_type:, case_state:, rs_state:, date:, third_party: false)
    kase = if third_party
             create(
               case_type,
               :third_party,
               current_state: case_state,
               date_responded: Time.zone.today,
               retention_schedule:
                 RetentionSchedule.new(
                   state: rs_state,
                   planned_destruction_date: date,
                 ),
             )
           else
             create(
               case_type,
               current_state: case_state,
               date_responded: Time.zone.today,
               retention_schedule:
                 RetentionSchedule.new(
                   state: rs_state,
                   planned_destruction_date: date,
                 ),
             )
           end

    kase.save!
    kase
  end
end
