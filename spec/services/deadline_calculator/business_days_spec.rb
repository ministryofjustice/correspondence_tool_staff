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
      let(:thu_jun_01) { Time.utc(2017, 6, 1, 12, 0, 0) }
      let(:fri_jun_02) { Time.utc(2017, 6, 2, 12, 0, 0) }
      let(:fri_jun_16) { Time.utc(2017, 6, 16, 12, 0, 0) }
      let(:thu_jun_15) { Time.utc(2017, 6, 15, 12, 0, 0) }
      let(:fri_jun_30) { Time.utc(2017, 6, 30, 12, 0, 0) }
      let(:fri_jul_14) { Time.utc(2017, 7, 14, 12, 0, 0) }

      describe '#time_units_desc_for_deadline' do
        it 'single' do
          expect(deadline_calculator.time_units_desc_for_deadline)
            .to eq "business day"
        end

        it 'plural' do
          expect(deadline_calculator.time_units_desc_for_deadline(2))
            .to eq "business days"
        end
      end

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

      describe '.extension_deadline' do
        it 'is 30 working days after received_date - not counting bank holiday Mon May 29' do
          Timecop.freeze thu_may_18 do
            expect(deadline_calculator.extension_deadline(10))
              .to eq fri_jun_30.to_date
          end
        end
      end

      describe '.max_allowed_deadline_date' do
        it 'is 40 working days after received_date - not counting bank holiday Mon May 29' do
          Timecop.freeze thu_may_18 do
            expect(deadline_calculator.max_allowed_deadline_date(20))
              .to eq fri_jul_14.to_date
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

      describe '#business_unit_deadline_for_date' do
        context 'non-trigger case' do
          it 'is 20 working days after specified date' do
            deadline = deadline_calculator.business_unit_deadline_for_date(thu_may_18)
            expect(deadline).to eq thu_jun_15.to_date
          end
        end

        context 'trigger case' do
          it 'is 10 working datas after specified date' do
            allow(foi_case).to receive(:flagged?).and_return(true)
            deadline_calculator = described_class.new(foi_case)
            deadline = deadline_calculator.business_unit_deadline_for_date(thu_may_18)
            expect(deadline).to eq thu_jun_01.to_date
          end
        end
      end
    end

    context 'received on a Saturday' do
      let(:sat_jul_03) { Time.utc(2021, 7, 3, 12, 0, 0) }
      let(:wed_jul_07) { Time.utc(2021, 7, 7, 12, 0, 0) }
      let(:fri_jul_16) { Time.utc(2021, 7, 16, 12, 0, 0) }
      let(:fri_jul_30) { Time.utc(2021, 7, 30, 12, 0, 0) }
      let(:sat_may_01) { Time.utc(2021, 5, 1, 12, 0, 0) }
      let(:tue_jun_01) { Time.utc(2021, 6, 1, 12, 0, 0) }
      let(:mon_may_17) { Time.utc(2021, 5, 17, 12, 0, 0) }
      let(:thu_may_06) { Time.utc(2021, 5, 6, 12, 0, 0) }

      describe '.escalation_deadline' do
        it 'is 3 working days after received date' do
          Timecop.freeze sat_jul_03 do
            expect(deadline_calculator.escalation_deadline)
              .to eq wed_jul_07.to_date
          end
        end

        it 'is 3 working days after received date - bank holiday Mon May 03 is not counted' do
          Timecop.freeze sat_may_01 do
            expect(deadline_calculator.escalation_deadline)
              .to eq thu_may_06.to_date
          end
        end
      end

      describe '.external_deadline' do
        it 'is 20 working days after received date' do
          Timecop.freeze sat_jul_03 do
            expect(deadline_calculator.external_deadline)
              .to eq fri_jul_30.to_date
          end
        end

        it 'is 20 working days after received date - bank holidays Mon May 03 and Mon May 31 are not counted' do
          Timecop.freeze sat_may_01 do
            expect(deadline_calculator.external_deadline)
              .to eq tue_jun_01.to_date
          end
        end
      end

      describe '.internal_deadline' do
        it 'is 10 working days after received date' do
          Timecop.freeze sat_jul_03 do
            expect(deadline_calculator.internal_deadline)
              .to eq fri_jul_16.to_date
          end
        end

        it 'is 10 working days after received date - bank holiday Mon May 03 is not counted' do
          Timecop.freeze sat_may_01 do
            expect(deadline_calculator.internal_deadline)
              .to eq mon_may_17.to_date
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

    context '#days_taken' do
      let(:thu_may_18) { Time.utc(2017, 5, 18, 12, 0, 0) }
      let(:tue_may_23) { Time.utc(2017, 5, 23, 12, 0, 0) }

      it 'same day' do
        expect(deadline_calculator.class.days_taken(thu_may_18.to_date, thu_may_18.to_date))
          .to eq 1
      end

      it 'start date ealier than end day' do
        expect(deadline_calculator.class.days_taken(thu_may_18.to_date, tue_may_23.to_date))
          .to eq 4
      end

      it 'start date later than end day' do
        thu_may_18 = Time.utc(2017, 5, 18, 12, 0, 0)
        tue_may_23 = Time.utc(2017, 5, 23, 12, 0, 0)
        expect(deadline_calculator.class.days_taken(tue_may_23.to_date, thu_may_18.to_date))
          .to eq 0
      end
    end

    context '#days_late' do
      let(:thu_may_18) { Time.utc(2017, 5, 18, 12, 0, 0) }
      let(:tue_may_23) { Time.utc(2017, 5, 23, 12, 0, 0) }

      it 'same day' do
        expect(deadline_calculator.class.days_late(thu_may_18.to_date, thu_may_18.to_date))
          .to eq 0
      end

      it 'start date earlier than end day' do
        expect(deadline_calculator.class.days_late(thu_may_18.to_date, tue_may_23.to_date))
          .to eq 3
      end

      it 'start date later than end day' do
        thu_may_18 = Time.utc(2017, 5, 18, 12, 0, 0)
        tue_may_23 = Time.utc(2017, 5, 23, 12, 0, 0)
        expect(deadline_calculator.class.days_late(tue_may_23.to_date, thu_may_18.to_date))
          .to eq 0
      end
    end
  end
end
