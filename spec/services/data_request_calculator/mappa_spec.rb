require "rails_helper"

describe DataRequestCalculator::Mappa do
  subject(:calculator) { described_class.new(data_request_area, start) }

  let(:kase) { create(:offender_sar_case) }
  let(:data_request_area) { create(:data_request_area, offender_sar_case: kase) }
  let(:start) { Date.new(2025, 1, 20) }
  let(:chase_one) { start + 21.days }
  let(:after_chase_one) { chase_one + 1.day }
  let(:chase_two) { start + 25.days }
  let(:after_chase_two) { chase_two + 1.day }
  let(:chase_three) { start + 29.days }
  let(:after_chase_three) { chase_three + 1.day }

  # Expected chase schedule
  # Day | Chase number | Email type
  # 0   | 0            | Day One
  # 21  | 1            | Chase
  # 25  | 2            | Chase Escalation
  # 29  | 3            | Chase Escalation
  # 33  | 4            | Chase Overdue

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
        Timecop.freeze(start) do
          expect(calculator.next_chase_date).to eq chase_one
        end
      end
    end

    context "when first chase not sent and the chase window has passed" do
      it "returns current day" do
        Timecop.freeze(after_chase_one) do
          expect(calculator.next_chase_date).to eq Date.current
        end
      end
    end

    context "when after 1st chase sent" do
      let(:last_chase_email) { chase_one }

      before do
        data_request_area.data_request_emails << create(:data_request_email, email_type: "chase", created_at: last_chase_email)
      end

      it "returns 4 days after previous chase sent" do
        Timecop.freeze(after_chase_one) do
          expect(calculator.next_chase_date).to eq last_chase_email + 4.days
        end
      end
    end
  end

  describe "#next_chase_type" do
    context "when case is closed" do
      let(:kase) { create(:offender_sar_case, :closed) }

      it "returns nil" do
        Timecop.freeze(start) do
          expect(calculator.next_chase_type).to be_nil
        end
      end
    end

    context "when before first chase" do
      it "returns standard chase" do
        Timecop.freeze(start) do
          expect(calculator.next_chase_type).to eq :chase_email
        end
      end
    end

    context "when first chase not sent and the chase window has passed" do
      it "returns standard chase" do
        Timecop.freeze(after_chase_one) do
          expect(calculator.next_chase_type).to eq :chase_email
        end
      end
    end

    context "when after 1st chase sent" do
      let(:last_chase_email) { chase_one }

      before do
        data_request_area.data_request_emails << create(:data_request_email, email_type: "chase", created_at: last_chase_email)
      end

      it "returns escalation chase" do
        Timecop.freeze(after_chase_one) do
          expect(calculator.next_chase_type).to eq :chase_escalation_email
        end
      end
    end

    context "when next chase date is when kase is past deadline" do
      let(:last_chase_email) { chase_three }

      before do
        data_request_area.data_request_emails << create(:data_request_email, email_type: "chase", created_at: last_chase_email)
        allow(kase).to receive(:external_deadline).and_return(start + 30.days)
      end

      it "returns overdue chase" do
        Timecop.freeze(after_chase_three) do
          expect(calculator.next_chase_type).to eq :chase_overdue_email
        end
      end
    end
  end
end
