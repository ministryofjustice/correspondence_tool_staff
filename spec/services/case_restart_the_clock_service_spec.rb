require "rails_helper"

describe CaseRestartTheClockService do
  let(:user)    { find_or_create :manager_approver }
  let(:kase)    { create(:sar_case, :stopped, received_date: Date.new(2025, 11, 1)) }
  let(:service) { described_class.new(user, kase, restart_the_clock_params) }

  before do
    service.call
  end

  RSpec.shared_examples "invalid restart the clock service" do
    it "fails to restart the clock", :aggregate_failures do
      case_transition = kase.transitions.last

      expect(service.result).to eq :validation_error
      expect(kase.current_state).to eq "stopped"
      expect(case_transition.message).to eq "Spec Stop the Clock"
    end
  end

  describe "#call" do
    context "when valid" do
      let(:restart_the_clock_params) do
        {
          restart_the_clock_date_yyyy: "2025",
          restart_the_clock_date_mm: "11",
          restart_the_clock_date_dd: "6",
        }
      end

      it "returns :ok result" do
        expect(service.result).to eq :ok
      end

      it "updates the case details" do
        expect(kase.current_state).to eq "unassigned"
      end

      it "generates a case transition" do
        case_transition = kase.transitions.last
        expected_message = <<~MSG
          Clock restarted from:  6 November 2025.
          Old final deadline:  1 December 2025.
          New final deadline:  2 December 2025.
        MSG

        expect(case_transition.message).to eq expected_message.strip
      end
    end

    context "when empty date" do
      let(:restart_the_clock_params) do
        {
          restart_the_clock_date_yyyy: nil,
          restart_the_clock_date_mm: nil,
          restart_the_clock_date_dd: nil,
        }
      end

      it_behaves_like "invalid restart the clock service"

      it "has error" do
        expect(kase.errors[:restart_the_clock_date]).to eq ["cannot be blank"]
      end
    end

    context "when early date" do
      let(:restart_the_clock_params) do
        {
          restart_the_clock_date_yyyy: 2025,
          restart_the_clock_date_mm: 10,
          restart_the_clock_date_dd: 31,
        }
      end

      it_behaves_like "invalid restart the clock service"

      it "has error" do
        expect(kase.errors[:restart_the_clock_date]).to eq ["cannot be before case was received"]
      end
    end

    context "when future date" do
      let(:restart_the_clock_params) do
        future_date = Time.zone.today + 1.day
        {
          restart_the_clock_date_yyyy: future_date.year,
          restart_the_clock_date_mm: future_date.month,
          restart_the_clock_date_dd: future_date.day,
        }
      end

      it_behaves_like "invalid restart the clock service"

      it "has error" do
        expect(kase.errors[:restart_the_clock_date]).to eq ["cannot be in the future"]
      end
    end
  end
end
