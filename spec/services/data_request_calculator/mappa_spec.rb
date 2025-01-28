require "rails_helper"

describe DataRequestCalculator::Mappa do
  subject(:calculator) { described_class.new(data_request_area, start) }

  let(:kase) { create(:offender_sar_case) }
  let(:data_request_area) { create(:data_request_area, offender_sar_case: kase) }
  let(:start) { Date.new(2025, 1, 20) }

  describe "#deadline_days" do
    it "is 20" do
      expect(calculator.deadline_days).to eq 20
    end
  end

  describe "#deadline" do
    it "is 20 days after the start date" do
      expect(calculator.deadline).to eq start + 20.days
    end
  end

  describe "#next_chase_date" do
    context "when case is closed" do
      let(:kase) { create(:offender_sar_case, :closed) }

      it "returns nil" do
        Timecop.freeze(Date.new(2025, 1, 20)) do
          expect(calculator.next_chase_date).to be_nil
        end
      end
    end

    context "when before first chase" do
      it "returns day after deadline" do
        Timecop.freeze(Date.new(2025, 1, 20)) do
          expect(calculator.next_chase_date).to eq start + 21.days
        end
      end
    end

    context "when first chase not sent and the chase window has passed" do
      it "returns current day" do
        Timecop.freeze(Date.new(2025, 1, 20) + 22.days) do
          expect(calculator.next_chase_date).to eq Date.current
        end
      end
    end

    context "when after 1st chase sent" do
      let(:last_chase_email) { start + 21.days }

      before do
        data_request_area.data_request_emails << create(:data_request_email, email_type: "chase", created_at: last_chase_email)
      end

      it "returns 4 days after previous chase sent" do
        Timecop.freeze(Date.new(2025, 1, 20) + 22.days) do
          expect(calculator.next_chase_date).to eq last_chase_email + 4.days
        end
      end
    end
  end

  describe "#next_chase_type" do
    context "when case is closed" do
      let(:kase) { create(:offender_sar_case, :closed) }

      it "returns nil" do
        Timecop.freeze(Date.new(2025, 1, 20)) do
          expect(calculator.next_chase_type).to be_nil
        end
      end
    end

    context "when before first chase" do
      it "returns standard chase" do
        Timecop.freeze(Date.new(2025, 1, 20)) do
          expect(calculator.next_chase_type).to eq :chase_email
        end
      end
    end

    context "when first chase not sent and the chase window has passed" do
      it "returns standard chase" do
        Timecop.freeze(Date.new(2025, 1, 20) + 22.days) do
          expect(calculator.next_chase_type).to eq :chase_email
        end
      end
    end

    context "when after 1st chase sent" do
      let(:last_chase_email) { start + 21.days }

      before do
        data_request_area.data_request_emails << create(:data_request_email, email_type: "chase", created_at: last_chase_email)
      end

      it "returns standard chase" do
        Timecop.freeze(Date.new(2025, 1, 20) + 22.days) do
          expect(calculator.next_chase_type).to eq :chase_email
        end
      end
    end

    context "when next chase date is when kase is past deadline" do
      let(:last_chase_email) { start + 28.days }

      before do
        data_request_area.data_request_emails << create(:data_request_email, email_type: "chase", created_at: last_chase_email)
        allow(kase).to receive(:external_deadline).and_return(start + 30.days)
      end

      it "returns overdue chase" do
        Timecop.freeze(Date.new(2025, 1, 20) + 29.days) do
          expect(calculator.next_chase_type).to eq :chase_overdue_email
        end
      end
    end
  end
end
