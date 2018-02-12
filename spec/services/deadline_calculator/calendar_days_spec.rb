require 'rails_helper'

describe DeadlineCalculator::CalendarDays do
  let(:sar)                 { find_or_create :sar_correspondence_type }
  let(:sar_case)            { create :sar_case }
  let(:deadline_calculator) { described_class.new sar_case }

  context 'SAR case' do
    describe 'escalation deadline' do
      it 'is 3 calendar days after the date of creation' do
        expect(deadline_calculator.escalation_deadline)
          .to eq 3.days.since(sar_case.created_at.to_date)
      end
    end

    describe 'internal deadline' do
      it 'is 10 calendar days after the date received' do
        expect(deadline_calculator.internal_deadline)
          .to eq 10.days.since(sar_case.received_date)
      end
    end

    describe 'external deadline' do
      it 'is 40 calendar days after the date received' do
        expect(deadline_calculator.external_deadline)
          .to eq 40.days.since(sar_case.received_date)
      end
    end
  end
end
