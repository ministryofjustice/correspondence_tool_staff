require "rails_helper"

describe DeadlineCalculator::BusinessDays do
  let(:thu_oct_19) { Date.new(2023, 10, 19) }
  let(:tue_oct_24) { Date.new(2023, 10, 24) }

  BusinessTimeConfig.additional_bank_holidays = [
    "2023-07-12", # Battle of the Boyne
    "2023-08-07", # Summer bank holiday
    "2023-11-30", # St Andrew's Day
    "2024-01-02", # 2nd January
    "2024-03-18", # St Patrick's Day
    "2024-07-12", # Battle of the Boyne
    "2024-08-05", # Summer bank holiday
    "2024-12-02", # St Andrew's Day (substitute day)
    "2025-01-02", # 2nd January
    "2025-03-17", # St Patricks's Day
    "2025-07-14", # Battle of the Boyne (substitute day)
    "2025-08-04", # Summer bank holiday
    "2025-12-01", # St Andrew's Day (substitute day)
    "2026-01-02", # 2nd January"
    "2026-03-17", # St Patrick's Day
    "2026-07-13", # Battle of the Boyne
    "2026-08-03", # Summer bank holiday
    "2026-11-30", # St Andrew's Day
    "2027-01-04", # 2nd January (substitute day)
  ].freeze

  describe "FOI requests" do
    let(:foi_case) do
      build_stubbed :foi_case,
                    received_date: Time.zone.today,
                    created_at: Time.zone.today
    end
    let(:deadline_calculator) { described_class.new foi_case }

    context "when received on a workday" do
      let(:thu_may_18) { Time.utc(2017, 5, 18, 12, 0, 0) }
      let(:tue_may_23) { Time.utc(2017, 5, 23, 12, 0, 0) }
      let(:thu_jun_01) { Time.utc(2017, 6, 1, 12, 0, 0) }
      let(:fri_jun_02) { Time.utc(2017, 6, 2, 12, 0, 0) }
      let(:fri_jun_16) { Time.utc(2017, 6, 16, 12, 0, 0) }
      let(:thu_jun_15) { Time.utc(2017, 6, 15, 12, 0, 0) }
      let(:fri_jun_30) { Time.utc(2017, 6, 30, 12, 0, 0) }
      let(:fri_jul_14) { Time.utc(2017, 7, 14, 12, 0, 0) }

      describe "#time_units_desc_for_deadline" do
        it "single" do
          expect(deadline_calculator.time_units_desc_for_deadline)
            .to eq "business day"
        end

        it "plural" do
          expect(deadline_calculator.time_units_desc_for_deadline(2))
            .to eq "business days"
        end
      end

      describe ".escalation_deadline" do
        it "is 3 days after created date" do
          Timecop.freeze thu_may_18 do
            expect(deadline_calculator.escalation_deadline)
              .to eq tue_may_23.to_date
          end
        end
      end

      describe ".external_deadline" do
        it "is 20 working days after received_date - not counting bank holiday Mon May 29" do
          Timecop.freeze thu_may_18 do
            expect(deadline_calculator.external_deadline)
              .to eq fri_jun_16.to_date
          end
        end
      end

      describe ".extension_deadline" do
        it "is 30 working days after received_date - not counting bank holiday Mon May 29" do
          Timecop.freeze thu_may_18 do
            expect(deadline_calculator.extension_deadline(10))
              .to eq fri_jun_30.to_date
          end
        end
      end

      describe ".max_allowed_deadline_date" do
        it "is 40 working days after received_date - not counting bank holiday Mon May 29" do
          Timecop.freeze thu_may_18 do
            expect(deadline_calculator.max_allowed_deadline_date(20))
              .to eq fri_jul_14.to_date
          end
        end
      end

      describe ".internal_deadline" do
        it "is 10 working days after received_date - not counting bank holiday Mon May 29" do
          Timecop.freeze thu_may_18 do
            expect(deadline_calculator.internal_deadline)
              .to eq fri_jun_02.to_date
          end
        end
      end

      describe "#business_unit_deadline_for_date" do
        context "and non-trigger case" do
          it "is 20 working days after specified date" do
            deadline = deadline_calculator.business_unit_deadline_for_date(thu_may_18)
            expect(deadline).to eq thu_jun_15.to_date
          end
        end

        context "and trigger case" do
          it "is 10 working datas after specified date" do
            allow(foi_case).to receive(:flagged?).and_return(true)
            deadline_calculator = described_class.new(foi_case)
            deadline = deadline_calculator.business_unit_deadline_for_date(thu_may_18)
            expect(deadline).to eq thu_jun_01.to_date
          end
        end
      end
    end

    context "when received on a Saturday" do
      let(:sat_jul_03) { Time.utc(2021, 7, 3, 12, 0, 0) }
      let(:wed_jul_07) { Time.utc(2021, 7, 7, 12, 0, 0) }
      let(:fri_jul_16) { Time.utc(2021, 7, 16, 12, 0, 0) }
      let(:fri_jul_30) { Time.utc(2021, 7, 30, 12, 0, 0) }
      let(:sat_may_01) { Time.utc(2021, 5, 1, 12, 0, 0) }
      let(:tue_jun_01) { Time.utc(2021, 6, 1, 12, 0, 0) }
      let(:mon_may_17) { Time.utc(2021, 5, 17, 12, 0, 0) }
      let(:thu_may_06) { Time.utc(2021, 5, 6, 12, 0, 0) }
      let(:mon_nov_27) { Time.utc(2023, 11, 27, 12, 0, 0) }
      let(:fri_dec_01) { Time.utc(2023, 12, 1, 12, 0, 0) }
      let(:tue_dec_12) { Time.utc(2023, 12, 12, 12, 0, 0) }
      let(:thu_dec_28) { Time.utc(2023, 12, 28, 12, 0, 0) }

      describe ".escalation_deadline" do
        it "is 3 working days after received date" do
          Timecop.freeze sat_jul_03 do
            expect(deadline_calculator.escalation_deadline)
              .to eq wed_jul_07.to_date
          end
        end

        it "is 3 working days after received date - bank holiday Mon May 03 is not counted" do
          Timecop.freeze sat_may_01 do
            expect(deadline_calculator.escalation_deadline)
              .to eq thu_may_06.to_date
          end
        end

        it "is 3 working days after received date - Scottish bank holiday Thu Nov 30 is not counted" do
          Timecop.freeze mon_nov_27 do
            expect(deadline_calculator.escalation_deadline)
              .to eq fri_dec_01.to_date
          end
        end
      end

      describe ".external_deadline" do
        it "is 20 working days after received date" do
          Timecop.freeze sat_jul_03 do
            expect(deadline_calculator.external_deadline)
              .to eq fri_jul_30.to_date
          end
        end

        it "is 20 working days after received date - bank holidays Mon May 03 and Mon May 31 are not counted" do
          Timecop.freeze sat_may_01 do
            expect(deadline_calculator.external_deadline)
              .to eq tue_jun_01.to_date
          end
        end

        it "is 20 working days after received date - Scottish bank holiday Thu Nov 30 and Christmas bank holidays are not counted" do
          Timecop.freeze mon_nov_27 do
            expect(deadline_calculator.external_deadline)
              .to eq thu_dec_28.to_date
          end
        end
      end

      describe ".internal_deadline" do
        it "is 10 working days after received date" do
          Timecop.freeze sat_jul_03 do
            expect(deadline_calculator.internal_deadline)
              .to eq fri_jul_16.to_date
          end
        end

        it "is 10 working days after received date - bank holiday Mon May 03 is not counted" do
          Timecop.freeze sat_may_01 do
            expect(deadline_calculator.internal_deadline)
              .to eq mon_may_17.to_date
          end
        end

        it "is 10 working days after received date - Scottish bank holiday Thu Nov 30 is not counted" do
          Timecop.freeze mon_nov_27 do
            expect(deadline_calculator.internal_deadline)
              .to eq tue_dec_12.to_date
          end
        end
      end
    end

    context "when escalation deadline" do
      let(:thu_may_18) { Time.utc(2017, 5, 18, 12, 0, 0) }
      let(:tue_may_23) { Time.utc(2017, 5, 23, 12, 0, 0) }

      it "accepts an optional date param" do
        expect(deadline_calculator.escalation_deadline(thu_may_18.to_date))
          .to eq tue_may_23.to_date
      end
    end

    describe "#time_taken" do
      let(:mon_nov_27) { Date.new(2023, 11, 27) }

      it "returns the number of business days taken to respond to a case" do
        Timecop.freeze mon_nov_27 do
          closed_case = create(:closed_case)
          deadline_calculator = described_class.new(closed_case)
          expect(deadline_calculator.time_taken).to eq 19
        end
      end

      it "returns nil for an open case" do
        expect(deadline_calculator.time_taken).to be_nil
      end
    end

    describe "#days_before" do
      it "includes additional bank holidays in calculation" do
        mon_dec_4 = Date.new(2023, 12, 4)
        fri_nov_17 = Date.new(2023, 11, 17)
        expect(deadline_calculator.days_before(10, mon_dec_4)).to eq fri_nov_17
      end
    end

    describe "#days_after" do
      it "includes additional bank holidays in calculation" do
        fri_nov_17 = Date.new(2023, 11, 17)
        mon_dec_4 = Date.new(2023, 12, 4)
        expect(deadline_calculator.days_after(10, fri_nov_17)).to eq mon_dec_4
      end
    end

    describe "#days_taken" do
      let(:thu_may_18) { Time.utc(2017, 5, 18, 12, 0, 0) }
      let(:tue_may_23) { Time.utc(2017, 5, 23, 12, 0, 0) }

      it "same day" do
        expect(deadline_calculator.days_taken(thu_may_18.to_date, thu_may_18.to_date))
          .to eq 1
      end

      it "start date earlier than end day" do
        expect(deadline_calculator.days_taken(thu_may_18.to_date, tue_may_23.to_date))
          .to eq 4
      end

      it "start date later than end day" do
        thu_may_18 = Time.utc(2017, 5, 18, 12, 0, 0)
        tue_may_23 = Time.utc(2017, 5, 23, 12, 0, 0)
        expect(deadline_calculator.days_taken(tue_may_23.to_date, thu_may_18.to_date))
          .to eq 0
      end

      it "includes additional holidays" do
        expect(thu_oct_19).to receive(:business_days_until).with(tue_oct_24, true, { holidays: ::BusinessTimeConfig.additional_bank_holidays })
        deadline_calculator.days_taken(thu_oct_19, tue_oct_24)
      end
    end

    describe "#days_late" do
      let(:thu_may_18) { Time.utc(2017, 5, 18, 12, 0, 0) }
      let(:tue_may_23) { Time.utc(2017, 5, 23, 12, 0, 0) }

      it "same day" do
        expect(deadline_calculator.days_late(thu_may_18.to_date, thu_may_18.to_date))
          .to eq 0
      end

      it "start date earlier than end day" do
        expect(deadline_calculator.days_late(thu_may_18.to_date, tue_may_23.to_date))
          .to eq 3
      end

      it "start date later than end day" do
        thu_may_18 = Time.utc(2017, 5, 18, 12, 0, 0)
        tue_may_23 = Time.utc(2017, 5, 23, 12, 0, 0)
        expect(deadline_calculator.days_late(tue_may_23.to_date, thu_may_18.to_date))
          .to eq 0
      end

      it "includes additional holidays" do
        expect(thu_oct_19).to receive(:business_days_until).with(tue_oct_24, false, { holidays: ::BusinessTimeConfig.additional_bank_holidays })
        deadline_calculator.days_late(thu_oct_19, tue_oct_24)
      end
    end
  end

  describe "OFFENDER_SAR_COMPLAINT requests" do
    let(:offender_sar_complaint) do
      build_stubbed :offender_sar_complaint,
                    received_date: Time.zone.today,
                    created_at: Time.zone.today
    end
    let(:deadline_calculator) { described_class.new offender_sar_complaint }

    describe "#days_before" do
      it "does not includes additional holidays in calculation" do
        mon_dec_4 = Date.new(2023, 12, 4)
        mon_nov_20 = Date.new(2023, 11, 20)
        expect(deadline_calculator.days_before(10, mon_dec_4)).to eq mon_nov_20
      end
    end

    describe "#days_taken" do
      it "does not includes additional holidays" do
        expect(thu_oct_19).to receive(:business_days_until).with(tue_oct_24, true, {})
        deadline_calculator.days_taken(thu_oct_19, tue_oct_24)
      end
    end

    describe "#days_late" do
      it "does not includes additional holidays" do
        expect(thu_oct_19).to receive(:business_days_until).with(tue_oct_24, false, {})
        deadline_calculator.days_late(thu_oct_19, tue_oct_24)
      end
    end
  end
end
