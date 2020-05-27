require 'rails_helper'

def generate_start_date(month, day)
    current_year = Date.current.year     
    if Date.new(current_year, month, day) > Date.today
        chosen_year = current_year-1
    else
        chosen_year = current_year
    end
    [chosen_year, Date.civil(chosen_year, month, day)]
end

def get_expected_deadline(base_date)
    expected_deadline = base_date
    while !expected_deadline.workday? || expected_deadline.bank_holiday?
        expected_deadline = expected_deadline.tomorrow
    end
    expected_deadline
end

describe DeadlineCalculator::CalendarMonth do
    let(:sar)                 { find_or_create :sar_correspondence_type }
    let(:sar_case)            { create :sar_case }
    let(:deadline_calculator) { described_class.new sar_case }
  
    context 'SAR case' do
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
        context 'general cases for deadlines' do
            dates_for_testing = [
              {"received_date" => { "month" => 1, "day" => 31 }, "expected_base_date" => { "month" => 2, "day" => -1 } }, 
              {"received_date" => { "month" => 6, "day" => 30 }, "expected_base_date" => { "month" => 7, "day" => 30 } }, 
              {"received_date" => { "month" => 2, "day" => -1 }, "expected_base_date" => { "month" => 3, "day" => 0 } }, 
              {"received_date" => { "month" => 3, "day" => 15 }, "expected_base_date" => { "month" => 4, "day" => 15 } }, 
            ]
            dates_for_testing.each do |date_for_testing|
              month = date_for_testing["received_date"]["month"]
              day = date_for_testing["received_date"]["day"]
              base_month = date_for_testing["expected_base_date"]["month"]
              which_year, received_date_used = generate_start_date(month, day)
              base_day = date_for_testing["expected_base_date"]["day"] 
              if base_day == 0 
                base_day = received_date_used.day
              end
              expected_deadline = get_expected_deadline(Date.civil(which_year, base_month, base_day))
              it 'Testing #{received_date_used} - #{expected_deadline}' do
                test_case = double('sar_case')
                allow(test_case).to receive(:received_date).and_return(received_date_used)
                deadline_calculator_local = described_class.new test_case
                expect(deadline_calculator_local.external_deadline).to eq expected_deadline
              end
            end
        end

        context 'the date of one calendar month later is non working date' do
          it 'weekend ' do
              received_date_used = Date.today
              while received_date_used.workday?
                received_date_used = received_date_used.yesterday
              end 
              test_case = double('sar_case')
              allow(test_case).to receive(:received_date).and_return(received_date_used)
              deadline_calculator_local = described_class.new test_case

              expect(deadline_calculator_local.external_deadline)
                .to eq get_expected_deadline(1.month.since(received_date_used))
          end    
          it 'bank_holiday' do
              received_date_used = 1.month.ago(Date.parse(BankHoliday.all.second.date))
              test_case = double('sar_case')
              allow(test_case).to receive(:received_date).and_return(received_date_used)
              deadline_calculator_local = described_class.new test_case

              expect(deadline_calculator_local.external_deadline)
              .to eq get_expected_deadline(1.month.since(received_date_used))
          end    
        end
      end
  
      describe '#buiness_unit_deadline_for_date' do
        context 'unflagged' do
          it 'is 30 days from date' do
            expect(sar_case).not_to be_flagged
            expect(deadline_calculator.business_unit_deadline_for_date())
            .to eq get_expected_deadline(1.month.since(sar_case.received_date))
          end
        end
  
        context 'flagged' do
          it 'is 10 days from date' do
            allow(sar_case).to receive(:flagged?).and_return(true)
            expect(deadline_calculator.business_unit_deadline_for_date()).to eq 10.days.since(sar_case.received_date)
          end
        end
  
      end
    end
end
  