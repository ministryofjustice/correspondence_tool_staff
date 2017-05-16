require 'rails_helper'

describe DeadlineCalculator do

  context 'FOI requests' do

    let(:foi_case) { build :case, category: build(:category, :foi), received_date: Date.today }

    context 'received on a workday' do
      let(:thu_may_18) { Date.new(2017, 5, 18) }
      let(:fri_may_26) { Date.new(2017, 5, 26) }
      let(:fri_jun_02) { Date.new(2017, 6, 2) }
      let(:fri_jun_16) { Date.new(2017, 6, 16) }

      describe '.escalation_deadline' do
        it 'is 6 days after received date' do
          Timecop.freeze thu_may_18 do
            expect(DeadlineCalculator.escalation_deadline(foi_case)).to eq fri_may_26
          end
        end
      end

      describe '.external_deadline' do
        it 'is 20 working days after received_date - not counting bank holiday Mon May 29' do
          Timecop.freeze thu_may_18 do
            expect(DeadlineCalculator.external_deadline(foi_case)).to eq fri_jun_16
          end
        end
      end

      describe '.internal_deadline' do
        it 'is 10 working days after received_date - not counting bank holiday Mon May 29' do
          Timecop.freeze thu_may_18 do
            expect(DeadlineCalculator.internal_deadline(foi_case)).to eq fri_jun_02
          end
        end
      end
    end

    context 'received on a Saturday' do

      let(:sat_jul_01) { Date.new(2017, 7, 1) }
      let(:mon_jul_10) { Date.new(2017, 7, 10) }
      let(:fri_jul_14) { Date.new(2017, 7, 14) }
      let(:fri_jul_28) { Date.new(2017, 7, 28) }

      describe '.escalation_deadline' do
        it 'is 6 days after first working day after received date' do
          Timecop.freeze sat_jul_01 do
            expect(DeadlineCalculator.escalation_deadline(foi_case)).to eq mon_jul_10
          end
        end
      end

      describe '.external_deadline' do
        it 'is 20 working days first working day after received date' do
          Timecop.freeze sat_jul_01 do
            expect(DeadlineCalculator.external_deadline(foi_case)).to eq fri_jul_28
          end
        end
      end

      describe '.internal_deadline' do
        it 'is 10 working days first working day after received date' do
          Timecop.freeze sat_jul_01 do
            expect(DeadlineCalculator.internal_deadline(foi_case)).to eq fri_jul_14
          end
        end
      end
    end
  end
end
