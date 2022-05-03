require "rails_helper"

describe RetentionSchedules::AddScheduleService do

  let(:closed_offender_sar_complaint) {
    create(
      :offender_sar_complaint, 
      :closed,
      retention_schedule:
        RetentionSchedule.new(
          planned_erasure_date: Date.today
        )
    )
  }

  let(:other_related_complaints) {
    rs_needed = [true, true, true, false, false]
    5.times.map.with_index do |_, i|
      create_offsar_complaint(rs_needed: rs_needed[i], state: :closed)
    end
  }

  let(:other_related_open_complaints) {
    2.times.map do
      create_offsar_complaint(rs_needed: false, state: :to_be_assessed)
    end
  }

  let(:closed_offender_sar) {
    create_offsar(rs_needed: false, state: :closed)
  }

  let(:closed_offender_sar_with_retention_schedule) {
    create_offsar(rs_needed: true, state: :closed)
  }

  let(:mock_case) {
    instance_double(
      Case::SAR::Standard, 
      offender_sar?: false,
      offender_sar_complaint?: false,
      last_transitioned_at: Date.today,
      closed?: true
    )
  }

  let(:expected_off_sar_erasure_date) {
    # i.e. the day this test is run
    closure_date = Date.today

    # defined as these in Settings.retention_timings.off_sars
    # and then referenced in service class
    (closure_date + 8.years + 6.months + 1.day)
  }

  before do
    # set up reverse links for original case
    original_case = closed_offender_sar_complaint.original_case
    original_case.linked_cases = 
      [closed_offender_sar_complaint] + 
      other_related_complaints +
      other_related_open_complaints
    original_case.save
  end

  describe 'cases service can mutate' do
    it 'cannot be cases other than offender sar' do
      service = RetentionSchedules::AddScheduleService.new(
        kase: mock_case
      )
      service.call

      expect(service.result).to be(:invalid_case)
    end
  end

  context 'when setting planned erasure dates on Offender SARs' do
    it 'sets the correct planned erasure date' do
      kase = closed_offender_sar

      service = RetentionSchedules::AddScheduleService.new(kase: kase)
      service.call

      expected_date = kase.retention_schedule.planned_erasure_date

      expect(kase.retention_schedule).to be_a(RetentionSchedule)
      expect(expected_date).to match(expected_off_sar_erasure_date)
    end

    it 'sets the correct planned erasure date when off sar already has a retention schedule' do
      retention_schedule = closed_offender_sar_with_retention_schedule.retention_schedule
      kase = closed_offender_sar_with_retention_schedule

      service = RetentionSchedules::AddScheduleService.new(kase: kase)
      service.call

      expected_date = kase.retention_schedule.planned_erasure_date

      expect(kase.retention_schedule).to be(retention_schedule)
      expect(expected_date).to match(expected_off_sar_erasure_date)
    end
  end

  context 'for planned erasure dates on Offender SARs Complaints' do
    it 'sets them correctly for the complaint and the original case' do
      retention_schedule = closed_offender_sar_complaint.retention_schedule
      kase = closed_offender_sar_complaint

      original_kase = closed_offender_sar_complaint.original_case

      service = RetentionSchedules::AddScheduleService.new(kase: kase)
      service.call

      expected_date = kase.retention_schedule.planned_erasure_date

      expected_original_kase_date = original_kase
        .retention_schedule
        .planned_erasure_date

      expect(kase.retention_schedule).to be(retention_schedule)
      expect(original_kase.retention_schedule).not_to be(retention_schedule)

      expect(expected_date).to match(expected_off_sar_erasure_date)
      expect(expected_original_kase_date).to match(expected_off_sar_erasure_date)
    end

    it 'sets them correctly on closed complaints related to the original case' do
      service = RetentionSchedules::AddScheduleService.new(
        kase: closed_offender_sar_complaint
      )
      service.call

      expected_date = closed_offender_sar_complaint
        .retention_schedule
        .planned_erasure_date

      original_kase = closed_offender_sar_complaint.original_case

      ok_retention_schedule = original_kase.retention_schedule

      other_related_complaints.each do |related_complaint|
        related_original_case = related_complaint.original_case

        related_case_date = related_complaint
          .retention_schedule
          .planned_erasure_date

        expect(ok_retention_schedule).to_not be(related_complaint.retention_schedule)
        expect(expected_date).to match(related_case_date)
        expect(expected_off_sar_erasure_date).to match(related_case_date)
        expect(original_kase).to match(related_original_case)
      end

      other_related_open_complaints.each do |related_complaint|
        related_original_case = related_complaint.original_case
        expect(related_complaint.retention_schedule).to be(nil)
      end
    end
  end

  def create_offsar(rs_needed:, state:)
    create(
      :offender_sar_case, 
      state,
      retention_schedule: 
        if rs_needed
          RetentionSchedule.new(
            planned_erasure_date: Date.today
          )
        else
          nil
        end
    )
  end

  def create_offsar_complaint(rs_needed:, state:)
    create(
      :offender_sar_complaint, 
      state,
      original_case: closed_offender_sar_complaint.original_case,
      retention_schedule: 
        if rs_needed
          RetentionSchedule.new(
            planned_erasure_date: Date.today
          )
        else
          nil
        end
    )
  end
end
