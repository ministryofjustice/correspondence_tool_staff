require 'rails_helper'

describe DeadlineCalculator::BusinessDays do

  context 'FOI requests' do

    let(:foi_case) { build :foi_case,
                           received_date: Date.today,
                           created_at: Date.today
    }
    let(:deadline_calculator) { described_class.new foi_case }

    context 'received on a workday' do
      let(:thu_may_18) { Time.utc(2017, 5, 18, 12, 0, 0) }
      let(:tue_may_23) { Time.utc(2017, 5, 23, 12, 0, 0) }
      let(:fri_jun_02) { Time.utc(2017, 6, 2, 12, 0, 0) }
      let(:fri_jun_16) { Time.utc(2017, 6, 16, 12, 0, 0) }

      describe '.escalation_deadline' do
        it 'is 3 days after created date' do
          Timecop.freeze thu_may_18 do
            expect(deadline_calculator.escalation_deadline)
              .to eq tue_may_23.to_date
          end
        end
      end

      describe '.external_deadline' do
        it 'is 20 working days after received_date - not counting bank holiday Mon May 29' do
          Timecop.freeze thu_may_18 do
            expect(deadline_calculator.external_deadline)
              .to eq fri_jun_16.to_date
          end
        end
      end

      describe '.internal_deadline' do
        it 'is 10 working days after received_date - not counting bank holiday Mon May 29' do
          Timecop.freeze thu_may_18 do
            expect(deadline_calculator.internal_deadline)
              .to eq fri_jun_02.to_date
          end
        end
      end
    end

    context 'received on a Saturday' do

      let(:sat_jul_01) { Date.new(2017, 7, 1) }
      let(:wed_jul_05) { Date.new(2017, 7, 5) }
      let(:fri_jul_14) { Date.new(2017, 7, 14) }
      let(:fri_jul_28) { Date.new(2017, 7, 28) }

      describe '.escalation_deadline' do
        it 'is 6 days after first working day after received date' do
          Timecop.freeze sat_jul_01 do
            expect(deadline_calculator.escalation_deadline)
              .to eq wed_jul_05.to_date
          end
        end
      end

      describe '.external_deadline' do
        it 'is 20 working days first working day after received date' do
          Timecop.freeze sat_jul_01 do
            expect(deadline_calculator.external_deadline)
              .to eq fri_jul_28.to_date
          end
        end
      end

      describe '.internal_deadline' do
        it 'is 10 working days first working day after received date' do
          Timecop.freeze sat_jul_01 do
            expect(deadline_calculator.internal_deadline)
              .to eq fri_jul_14.to_date
          end
        end
      end
    end

    context 'escalation deadline' do
      let(:thu_may_18) { Time.utc(2017, 5, 18, 12, 0, 0) }
      let(:tue_may_23) { Time.utc(2017, 5, 23, 12, 0, 0) }

      it 'accepts an optional date param' do
        expect(deadline_calculator.escalation_deadline(thu_may_18.to_date))
          .to eq tue_may_23.to_date
      end
    end
  end
end
