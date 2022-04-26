require "rails_helper"

describe RetentionSchedules::PlannedErasureDateService do
  let(:closed_offender_sar) {
    create(
      :offender_sar_case, 
      :closed,
      identifier: 'closed offender sar',
      received_date: 4.weeks.ago
    )
  }

  let(:mock_case) {
    instance_double(
      Case::SAR::Standard, 
      offender_sar?: false,
      last_transitioned_at: Date.today,
      closed?: true
    )
  }

  let(:expected_off_sar_erasure_date) {
    # defined in Settings referenced in service class
    years = 8.years
    months = 6.months
    added_days = 1.day

    # i.e. the day this test is run
    closure_date = Date.today
    
    (closure_date + years + months + added_days)
  }

  let!(:closed_offender_sar_with_retention_schedule) {
    kase = create(:offender_sar_case, :closed,
    identifier: 'closed offender sar',
    received_date: 4.weeks.ago,
    retention_schedule: 
      RetentionSchedule.new(
        planned_erasure_date: Date.today
      )
    )

    kase.save
    kase
  }

  describe 'cases service can mutate' do
    it 'cannot be cases other than offender sar' do
      service = RetentionSchedules::PlannedErasureDateService.new(
        kase: mock_case
      )
      service.call

      expect(service.result).to be(:invalid_case)
    end
  end

  context 'when setting planned erasure dates on offender sars' do
    it 'sets the correct planned erasure date' do
      kase = closed_offender_sar

      service = RetentionSchedules::PlannedErasureDateService.new(kase: kase)
      service.call

      expected_date = kase.retention_schedule.planned_erasure_date
      
      expect(kase.retention_schedule).to be_a(RetentionSchedule)
      expect(expected_date).to match(expected_off_sar_erasure_date)
    end

    it 'sets the correct planned erasure date when off sar already has a retention schedule' do
      retention_schedule = closed_offender_sar_with_retention_schedule.retention_schedule
      kase = closed_offender_sar_with_retention_schedule

      service = RetentionSchedules::PlannedErasureDateService.new(kase: kase)
      service.call

      expected_date = kase.retention_schedule.planned_erasure_date

      expect(kase.retention_schedule).to be(retention_schedule)
      expect(expected_date).to match(expected_off_sar_erasure_date)
    end
  end
end
