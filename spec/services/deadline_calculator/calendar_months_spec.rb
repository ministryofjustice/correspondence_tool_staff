require "rails_helper"

describe DeadlineCalculator::CalendarMonths do
  let(:sar)                 { find_or_create(:sar_correspondence_type) }
  let(:sar_case)            { freeze_time { create(:sar_case) } }
  let(:deadline_calculator) { described_class.new(sar_case) }

  describe "SAR case" do
    describe "#time_units_desc_for_deadline" do
      it "single" do
        expect(deadline_calculator.time_units_desc_for_deadline)
          .to eq "calendar month"
      end

      it "plural" do
        expect(deadline_calculator.time_units_desc_for_deadline(2))
          .to eq "calendar months"
      end
    end

    describe "#escalation deadline" do
      it "is 3 calendar days after the date of creation" do
        expect(deadline_calculator.escalation_deadline)
          .to eq 3.days.since(sar_case.created_at.to_date)
      end
    end

    describe "#internal deadline" do
      it "is 10 calendar days after the date received" do
        expect(deadline_calculator.internal_deadline)
          .to eq 10.days.since(sar_case.received_date)
      end
    end

    describe "#internal_deadline_for_date" do
      it "is 10 calendar days from the supplied date" do
        expect(deadline_calculator.internal_deadline_for_date(sar, Date.new(2018, 6, 25))).to eq Date.new(2018, 7, 5)
      end
    end

    describe "#external deadline" do
      describe "general cases for deadlines" do
        dates_for_testing = [
          { "received_date" => { "month" => 1, "day" => 31 }, "expected_base_date" => { "month" => 2, "day" => -1 } },
          { "received_date" => { "month" => 6, "day" => 30 }, "expected_base_date" => { "month" => 7, "day" => 30 } },
          { "received_date" => { "month" => 2, "day" => -1 }, "expected_base_date" => { "month" => 3, "day" => 0 } },
          { "received_date" => { "month" => 3, "day" => 15 }, "expected_base_date" => { "month" => 4, "day" => 15 } },
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
          it "Testing #{received_date_used} - #{expected_deadline}" do
            test_case = instance_double(Case::Base)
            allow(test_case).to receive(:received_date).and_return(received_date_used)
            allow(test_case).to receive(:correspondence_type).and_return(sar)
            deadline_calculator_local = described_class.new test_case
            expect(deadline_calculator_local.external_deadline).to eq expected_deadline
          end
        end
      end

      context "when deadline falls in non-working day based on calender month" do
        it "deadline falls on weekend and final_deadline should be next working day" do
          Timecop.freeze Time.zone.local(2019, 9, 27, 13, 21, 33) do
            test_case = instance_double(Case::Base)
            allow(test_case).to receive(:received_date).and_return(Time.zone.today)
            allow(test_case).to receive(:correspondence_type).and_return(sar)
            deadline_calculator_local = described_class.new test_case

            expect(deadline_calculator_local.external_deadline)
              .to eq Date.parse("2019-10-28")
          end
        end

        it "deadline falls on bank_holiday and final_deadline should be next working day" do
          Timecop.freeze Time.zone.local(2019, 9, 27, 13, 21, 33) do
            test_case = instance_double(Case::Base)
            allow(test_case).to receive(:received_date).and_return(Date.parse("2019-04-06"))
            allow(test_case).to receive(:correspondence_type).and_return(sar)
            deadline_calculator_local = described_class.new test_case

            expect(deadline_calculator_local.external_deadline)
            .to eq Date.parse("2019-05-07")
          end
        end
      end
    end

    describe "#buiness_unit_deadline_for_date" do
      context "when unflagged" do
        it "is 30 days from date" do
          expect(sar_case).not_to be_flagged
          expect(deadline_calculator.business_unit_deadline_for_date)
          .to eq get_expected_deadline(1.month.since(sar_case.received_date))
        end
      end

      context "when flagged" do
        it "is 10 days from date" do
          allow(sar_case).to receive(:flagged?).and_return(true)
          expect(deadline_calculator.business_unit_deadline_for_date).to eq 10.days.since(sar_case.received_date)
        end
      end
    end

    describe "#extension_deadline" do
      it "1 months" do
        Timecop.freeze Time.zone.local(2019, 8, 27, 13, 21, 33) do
          test_case = instance_double(Case::Base)
          allow(test_case).to receive(:received_date).and_return(Time.zone.today)
          allow(test_case).to receive(:correspondence_type).and_return(sar)
          deadline_calculator_local = described_class.new test_case

          expect(deadline_calculator_local.extension_deadline(1))
            .to eq Date.parse("2019-10-28")
        end
      end

      it "2 months" do
        Timecop.freeze Time.zone.local(2019, 9, 26, 13, 21, 33) do
          test_case = instance_double(Case::Base)
          allow(test_case).to receive(:received_date).and_return(Time.zone.today)
          allow(test_case).to receive(:correspondence_type).and_return(sar)
          deadline_calculator_local = described_class.new test_case

          expect(deadline_calculator_local.extension_deadline(2))
            .to eq Date.parse("2019-12-27")
        end
      end
    end

    describe "#max_allowed_deadline_date" do
      it "2 months" do
        Timecop.freeze Time.zone.local(2019, 10, 1, 13, 21, 33) do
          test_case = instance_double(Case::Base)
          allow(test_case).to receive(:received_date).and_return(Time.zone.today)
          allow(test_case).to receive(:correspondence_type).and_return(sar)
          deadline_calculator_local = described_class.new test_case

          expect(deadline_calculator_local.max_allowed_deadline_date)
            .to eq Date.parse("2020-01-02")
        end
      end
    end
  end

  describe "#days_taken" do
    let(:thu_may_18) { Time.utc(2017, 5, 18, 12, 0, 0) }
    let(:tue_may_23) { Time.utc(2017, 5, 23, 12, 0, 0) }

    it "same day" do
      expect(deadline_calculator.days_taken(thu_may_18.to_date, thu_may_18.to_date))
        .to eq 1
    end

    it "start date ealier than end day" do
      expect(deadline_calculator.days_taken(thu_may_18.to_date, tue_may_23.to_date))
        .to eq 6
    end

    it "start date later than end day" do
      thu_may_18 = Time.utc(2017, 5, 18, 12, 0, 0)
      tue_may_23 = Time.utc(2017, 5, 23, 12, 0, 0)
      expect(-deadline_calculator.days_taken(tue_may_23.to_date, thu_may_18.to_date))
        .to eq 4
    end
  end

  describe "#days_late" do
    let(:thu_may_18) { Time.utc(2017, 5, 18, 12, 0, 0) }
    let(:tue_may_23) { Time.utc(2017, 5, 23, 12, 0, 0) }

    it "same day" do
      expect(deadline_calculator.days_late(thu_may_18.to_date, thu_may_18.to_date))
        .to eq 0
    end

    it "start date ealier than end day" do
      expect(deadline_calculator.days_late(thu_may_18.to_date, tue_may_23.to_date))
        .to eq 5
    end

    it "start date later than end day" do
      thu_may_18 = Time.utc(2017, 5, 18, 12, 0, 0)
      tue_may_23 = Time.utc(2017, 5, 23, 12, 0, 0)
      expect(-deadline_calculator.days_late(tue_may_23.to_date, thu_may_18.to_date))
        .to eq 5
    end
  end
end
