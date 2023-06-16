require "rails_helper"

describe RetentionSchedules::AddScheduleService do
  let(:user) { find_or_create :branston_user }

  let(:closed_offender_sar_complaint) do
    create(
      :offender_sar_complaint,
      :closed,
      :with_retention_schedule,
    )
  end

  let(:other_related_complaints) do
    with_rs_cases = 3.times.map do
      create(
        :offender_sar_complaint,
        :closed,
        :with_retention_schedule,
        original_case: closed_offender_sar_complaint.original_case,
      )
    end

    without_rs_cases = 2.times.map do
      create(
        :offender_sar_complaint,
        :closed,
        original_case: closed_offender_sar_complaint.original_case,
      )
    end

    with_rs_cases + without_rs_cases
  end

  let(:other_related_open_complaints) do
    2.times.map do
      create(
        :offender_sar_complaint,
        :to_be_assessed,
        original_case: closed_offender_sar_complaint.original_case,
      )
    end
  end

  let(:closed_offender_sar) do
    create(
      :offender_sar_case,
      :closed,
    )
  end

  let(:closed_offender_sar_with_retention_schedule) do
    create(
      :offender_sar_case,
      :closed,
      :with_retention_schedule,
    )
  end

  let(:mock_case) do
    instance_double(
      Case::SAR::Standard,
      offender_sar?: false,
      offender_sar_complaint?: false,
      last_transitioned_at: Time.zone.today,
      closed?: true,
    )
  end

  let(:mock_open_case) do
    instance_double(
      Case::SAR::Offender,
      offender_sar?: true,
      offender_sar_complaint?: false,
      last_transitioned_at: Time.zone.today,
      closed?: false,
    )
  end

  let(:expected_off_sar_erasure_date) do
    # defined as these in Settings.retention_timings.off_sars
    # and then referenced in service class
    (4.business_days.ago + 8.years + 6.months).to_date
  end

  before do
    # set up reverse links for original case
    original_case = closed_offender_sar_complaint.original_case
    original_case.linked_cases =
      [closed_offender_sar_complaint] +
      other_related_complaints +
      other_related_open_complaints
    original_case.save!
  end

  describe "what types of case service can act upon" do
    it "cannot change cases other than offender sar or complaints" do
      service = described_class.new(
        kase: mock_case, user:,
      )

      service.call
      expect(service.result).to be(:invalid_case_type)
    end

    it "cannot add retention schedules to open cases" do
      service = described_class.new(
        kase: mock_open_case, user:,
      )
      service.call

      expect(service.result).to be(:invalid_as_case_is_open)
      expect(service).not_to receive(:add_retention_schedule)
      expect(service).not_to receive(:add_retention_schedules)
    end
  end

  context "when setting planned erasure dates on Offender SARs" do
    it "sets the correct planned erasure date" do
      kase = closed_offender_sar

      service = described_class.new(
        kase:, user:,
      )
      service.call

      expected_date = kase.retention_schedule.planned_destruction_date

      expect(kase.retention_schedule).to be_a(RetentionSchedule)
      expect(expected_date).to match(expected_off_sar_erasure_date)

      check_last_transition(
        kase, "Destruction date set to #{expected_date.strftime('%d-%m-%Y')}"
      )
    end

    it "sets the correct planned erasure date when an off sar already has a retention schedule" do
      retention_schedule = closed_offender_sar_with_retention_schedule.retention_schedule
      previous_date = retention_schedule.planned_destruction_date
      kase = closed_offender_sar_with_retention_schedule

      service = described_class.new(
        kase:, user:,
      )
      service.call

      expected_date = kase.retention_schedule.planned_destruction_date

      expect(service.result).to be(:success)
      expect(kase.retention_schedule).to eq(retention_schedule)
      expect(expected_date).to match(expected_off_sar_erasure_date)

      check_last_transition(
        kase, "Destruction date changed from #{previous_date.strftime('%d-%m-%Y')} to #{expected_date.strftime('%d-%m-%Y')}"
      )
    end
  end

  context "for planned erasure dates on Offender SARs Complaints" do
    it "sets them correctly for the complaint and the original case" do
      retention_schedule = closed_offender_sar_complaint.retention_schedule
      previous_date = retention_schedule.planned_destruction_date
      kase = closed_offender_sar_complaint
      original_kase = closed_offender_sar_complaint.original_case

      service = described_class.new(
        kase:, user:,
      )
      service.call

      expected_date = kase.retention_schedule.planned_destruction_date

      expected_original_kase_date = original_kase
        .retention_schedule
        .planned_destruction_date

      expect(kase.retention_schedule).to eq(retention_schedule)
      expect(original_kase.retention_schedule).not_to eq(retention_schedule)

      expect(expected_date).to match(expected_off_sar_erasure_date)
      expect(expected_original_kase_date).to match(expected_off_sar_erasure_date)

      check_last_transition(
        kase, "Destruction date changed from #{previous_date.strftime('%d-%m-%Y')} to #{expected_date.strftime('%d-%m-%Y')}"
      )
      check_last_transition(
        original_kase, "Destruction date set to #{expected_date.strftime('%d-%m-%Y')}"
      )
    end

    it "sets them correctly on closed complaints related to the original case" do
      service = described_class.new(
        kase: closed_offender_sar_complaint, user:,
      )
      service.call

      expected_date = closed_offender_sar_complaint
        .retention_schedule
        .planned_destruction_date

      original_kase = closed_offender_sar_complaint.original_case

      ok_retention_schedule = original_kase.retention_schedule

      other_related_complaints.each do |related_complaint|
        related_original_case = related_complaint.original_case

        related_case_date = related_complaint
          .retention_schedule
          .planned_destruction_date

        expect(ok_retention_schedule).not_to be(related_complaint.retention_schedule)
        expect(expected_date).to match(related_case_date)
        expect(expected_off_sar_erasure_date).to match(related_case_date)
        expect(original_kase).to match(related_original_case)
      end

      other_related_open_complaints.each do |related_complaint|
        expect(related_complaint.retention_schedule).to be(nil)
      end
    end
  end

  def check_last_transition(kase, message)
    transition = kase.transitions.last

    expect(transition.event).to eq("annotate_system_retention_changes")
    expect(transition.acting_user).to eq(user)
    expect(transition.acting_team).to eq(user.teams.last)
    expect(transition.message).to eq(message)
  end
end
