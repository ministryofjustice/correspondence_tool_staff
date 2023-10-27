require "rails_helper"

describe DeadlineCalculator::CalendarDays do
  let(:sar)                 { find_or_create :sar_correspondence_type }
  let(:sar_case)            { create :overturned_ico_sar }
  let(:deadline_calculator) { described_class.new sar_case }
  let(:start_date)          { Date.new(2018, 6, 14) }
  let(:start_date_plus_10)  { Date.new(2018, 6, 24) }
  let(:start_date_plus_30)  { Date.new(2018, 7, 14) }

  describe "SAR case" do
    describe "#time_units_desc_for_deadline" do
      it "single" do
        expect(deadline_calculator.time_units_desc_for_deadline)
          .to eq "calendar day"
      end

      it "plural" do
        expect(deadline_calculator.time_units_desc_for_deadline(2))
          .to eq "calendar days"
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
      it "is 30 calendar days after the date received" do
        expect(deadline_calculator.external_deadline)
          .to eq 30.days.since(sar_case.received_date)
      end
    end

    describe "#extension deadline" do
      it "is 30 calendar days after the date received" do
        expect(deadline_calculator.extension_deadline(30))
          .to eq 60.days.since(sar_case.received_date)
      end
    end

    describe "#max_allowed_deadline_date" do
      it "is 60 calendar days after the date received" do
        expect(deadline_calculator.max_allowed_deadline_date(60))
          .to eq 90.days.since(sar_case.received_date)
      end
    end

    describe "#buiness_unit_deadline_for_date" do
      context "when unflagged" do
        it "is 30 days from date" do
          expect(sar_case).not_to be_flagged
          expect(deadline_calculator.business_unit_deadline_for_date(start_date)).to eq start_date_plus_30
        end
      end

      context "when flagged" do
        it "is 10 days from date" do
          allow(sar_case).to receive(:flagged?).and_return(true)
          expect(deadline_calculator.business_unit_deadline_for_date(start_date)).to eq start_date_plus_10
        end
      end
    end
  end

  describe "#time_taken" do
    let(:closed_case) { create(:closed_case) }

    it "returns the number of calendar days taken to respond to a case" do
      freeze_time do
        deadline_calculator = described_class.new(closed_case)
        expect(deadline_calculator.time_taken).to eq 27
      end
    end

    it "returns nil for an open case" do
      expect(deadline_calculator.time_taken).to be_nil
    end

    it "returns 1 if number of days is < 1" do
      closed_case.date_responded = closed_case.received_date
      deadline_calculator = described_class.new(closed_case)
      expect(deadline_calculator.time_taken).to eq 1
    end
  end

  describe "#days_taken" do
    let(:thu_may_18) { Time.utc(2017, 5, 18, 12, 0, 0) }
    let(:tue_may_23) { Time.utc(2017, 5, 23, 12, 0, 0) }

    it "same day" do
      expect(deadline_calculator.class.days_taken(thu_may_18.to_date, thu_may_18.to_date))
        .to eq 1
    end

    it "start date ealier than end day" do
      expect(deadline_calculator.class.days_taken(thu_may_18.to_date, tue_may_23.to_date))
        .to eq 6
    end

    it "start date later than end day" do
      thu_may_18 = Time.utc(2017, 5, 18, 12, 0, 0)
      tue_may_23 = Time.utc(2017, 5, 23, 12, 0, 0)
      expect(-deadline_calculator.class.days_taken(tue_may_23.to_date, thu_may_18.to_date))
        .to eq 4
    end
  end

  describe "#days_late" do
    let(:thu_may_18) { Time.utc(2017, 5, 18, 12, 0, 0) }
    let(:tue_may_23) { Time.utc(2017, 5, 23, 12, 0, 0) }

    it "same day" do
      expect(deadline_calculator.class.days_late(thu_may_18.to_date, thu_may_18.to_date))
        .to eq 0
    end

    it "start date ealier than end day" do
      expect(deadline_calculator.class.days_late(thu_may_18.to_date, tue_may_23.to_date))
        .to eq 5
    end

    it "start date later than end day" do
      thu_may_18 = Time.utc(2017, 5, 18, 12, 0, 0)
      tue_may_23 = Time.utc(2017, 5, 23, 12, 0, 0)
      expect(-deadline_calculator.class.days_late(tue_may_23.to_date, thu_may_18.to_date))
        .to eq 5
    end
  end
end
