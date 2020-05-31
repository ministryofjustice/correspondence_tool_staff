require 'rails_helper'

describe DeadlineCalculator::CalendarDays do
  let(:sar)                 { find_or_create :sar_correspondence_type }
  let(:sar_case)            { create :overturned_ico_sar }
  let(:deadline_calculator) { described_class.new sar_case }
  let(:start_date)          { Date.new(2018, 6, 14) }
  let(:start_date_plus_10)  { Date.new(2018, 6, 24) }
  let(:start_date_plus_30)  { Date.new(2018, 7, 14) }

  context 'SAR case' do
    describe '#time_units_desc_for_deadline' do
      it 'single' do
        expect(deadline_calculator.time_units_desc_for_deadline)
          .to eq "calendar day"
      end

      it 'plural' do
        expect(deadline_calculator.time_units_desc_for_deadline(true))
          .to eq "calendar days"
      end
    end

    describe '#escalation deadline' do
      it 'is 3 calendar days after the date of creation' do
        expect(deadline_calculator.escalation_deadline)
          .to eq 3.days.since(sar_case.created_at.to_date)
      end
    end

    describe '#internal deadline' do
      it 'is 10 calendar days after the date received' do
        expect(deadline_calculator.internal_deadline)
          .to eq 10.days.since(sar_case.received_date)
      end
    end

    describe '#internal_deadline_for_date' do
      it 'is 10 calendar days from the supplied date' do
        expect(deadline_calculator.internal_deadline_for_date(sar, Date.new(2018, 6, 25))).to eq Date.new(2018, 7, 5)
      end
    end

    describe '#external deadline' do
      it 'is 30 calendar days after the date received' do
        expect(deadline_calculator.external_deadline)
          .to eq 30.days.since(sar_case.received_date)
      end
    end

    describe '#extension deadline' do
      it 'is 30 calendar days after the date received' do
        expect(deadline_calculator.extension_deadline(30))
          .to eq 60.days.since(sar_case.received_date)
      end
    end

    describe '#max_allowed_deadline_date' do
      it 'is 60 calendar days after the date received' do
        expect(deadline_calculator.max_allowed_deadline_date(60))
          .to eq 90.days.since(sar_case.received_date)
      end
    end

    describe '#buiness_unit_deadline_for_date' do
      context 'unflagged' do
        it 'is 30 days from date' do
          expect(sar_case).not_to be_flagged
          expect(deadline_calculator.business_unit_deadline_for_date(start_date)).to eq start_date_plus_30
        end
      end

      context 'flagged' do
        it 'is 10 days from date' do
          allow(sar_case).to receive(:flagged?).and_return(true)
          expect(deadline_calculator.business_unit_deadline_for_date(start_date)).to eq start_date_plus_10
        end
      end

    end
  end
end
