require "rails_helper"

describe CaseStopTheClockService do
  let(:user)    { find_or_create :manager_approver }
  let(:kase)    { create(:sar_case, received_date: Date.new(2025, 11, 1)) }
  let(:service) { described_class.new(user, kase, stop_the_clock_params) }

  RSpec.shared_examples "invalid stop the clock service" do
    it "fails to stop the clock", :aggregate_failures do
      case_transition = kase.transitions.last

      expect(service.result).to eq :validation_error
      expect(kase.current_state).to eq "unassigned"
      expect(case_transition.message).to be_nil
    end
  end

  describe "#call" do
    before do
      service.call
    end

    context "when valid" do
      let(:stop_the_clock_params) do
        {
          stop_the_clock_date_yyyy: "2025",
          stop_the_clock_date_mm: "11",
          stop_the_clock_date_dd: "6",
          stop_the_clock_categories: ["Category 1 - Sub Category", "Category 2 - Another Sub Category", "Category 3", "", "Category 3"],
          stop_the_clock_reason: "Testing stopping the clock",
        }
      end

      it "returns :ok result" do
        expect(service.result).to eq :ok
      end

      it "updates the case details" do
        expect(kase.current_state).to eq "stopped"
      end

      it "generates a case transition" do
        case_transition = kase.transitions.last
        expected_message = <<~MSG
          Clock stopped on:  6 November 2025.
          Reason: Category 1 - Sub Category.
          Reason: Category 2 - Another Sub Category.
          Reason: Category 3.

          Description: Testing stopping the clock
        MSG

        expect(case_transition.message).to eq expected_message.strip
      end
    end

    context "when empty categories" do
      let(:stop_the_clock_params) do
        {
          stop_the_clock_date_yyyy: "2025",
          stop_the_clock_date_mm: "11",
          stop_the_clock_date_dd: "6",
          stop_the_clock_categories: [],
          stop_the_clock_reason: "Testing stopping the clock",
        }
      end

      it_behaves_like "invalid stop the clock service"

      it "has error" do
        expect(kase.errors[:stop_the_clock_categories]).to eq ["must be selected"]
      end
    end

    context "when nil categories" do
      let(:stop_the_clock_params) do
        {
          stop_the_clock_date_yyyy: "2025",
          stop_the_clock_date_mm: "11",
          stop_the_clock_date_dd: "6",
          stop_the_clock_categories: nil,
          stop_the_clock_reason: "Testing stopping the clock",
        }
      end

      it_behaves_like "invalid stop the clock service"

      it "has error" do
        expect(kase.errors[:stop_the_clock_categories]).to eq ["must be selected"]
      end
    end

    context "when invalid reason" do
      let(:stop_the_clock_params) do
        {
          stop_the_clock_date_yyyy: "2025",
          stop_the_clock_date_mm: "11",
          stop_the_clock_date_dd: "6",
          stop_the_clock_categories: ["Category 1 - Sub Category"],
          stop_the_clock_reason: "",
        }
      end

      it_behaves_like "invalid stop the clock service"

      it "has error" do
        expect(kase.errors[:stop_the_clock_reason]).to eq ["cannot be blank"]
      end
    end

    context "when empty date" do
      let(:stop_the_clock_params) do
        {
          stop_the_clock_date_yyyy: nil,
          stop_the_clock_date_mm: nil,
          stop_the_clock_date_dd: nil,
          stop_the_clock_categories: ["Category 1 - Sub Category"],
          stop_the_clock_reason: "Testing stopping the clock",
        }
      end

      it_behaves_like "invalid stop the clock service"

      it "has error" do
        expect(kase.errors[:stop_the_clock_date]).to eq ["cannot be blank"]
      end
    end

    context "when before received date" do
      let(:stop_the_clock_params) do
        {
          stop_the_clock_date_yyyy: 2025,
          stop_the_clock_date_mm: 10,
          stop_the_clock_date_dd: 31,
          stop_the_clock_categories: ["Category 1 - Sub Category"],
          stop_the_clock_reason: "Testing stopping the clock",
        }
      end

      it_behaves_like "invalid stop the clock service"

      it "has error" do
        expect(kase.errors[:stop_the_clock_date]).to eq ["cannot be before the case was received"]
      end
    end

    context "when future date" do
      let(:stop_the_clock_params) do
        future_date = Time.zone.today + 1.day
        {
          stop_the_clock_date_yyyy: future_date.year,
          stop_the_clock_date_mm: future_date.month,
          stop_the_clock_date_dd: future_date.day,
          stop_the_clock_categories: ["Category 1 - Sub Category"],
          stop_the_clock_reason: "Testing stopping the clock",
        }
      end

      it_behaves_like "invalid stop the clock service"

      it "has error" do
        expect(kase.errors[:stop_the_clock_date]).to eq ["cannot be in the future"]
      end
    end

    context "when already stopped" do
      let(:kase) { create(:sar_case, :stopped, received_date: Date.new(2025, 11, 1)) }
      let(:stop_the_clock_params) do
        {
          stop_the_clock_date_yyyy: "2025",
          stop_the_clock_date_mm: "11",
          stop_the_clock_date_dd: "6",
          stop_the_clock_categories: ["Category 1 - Sub Category", "Category 2 - Another Sub Category", "Category 3", "", "Category 3"],
          stop_the_clock_reason: "Testing stopping the clock",
        }
      end

      it "has error" do
        expect(service.result).to eq :error
        expect(service.error.message).to include "No event stop_the_clock for role manager and case state stopped"
        expect(kase.errors).to be_empty
      end
    end

    context "when before last restart" do
      let(:kase) do
        sar = create(:sar_case, :stopped, received_date: Date.new(2025, 11, 1))

        restart_details = {
          restart_the_clock_date: Date.new(2025, 11, 15),
          new_status: sar.current_state,
        }

        create(:case_transition_restart_the_clock, case: sar, details: restart_details)

        sar
      end

      let(:stop_the_clock_params) do
        {
          stop_the_clock_date_yyyy: "2025",
          stop_the_clock_date_mm: "11",
          stop_the_clock_date_dd: "14",
          stop_the_clock_categories: ["Category 1 - Sub Category", "Category 2 - Another Sub Category", "Category 3", "", "Category 3"],
          stop_the_clock_reason: "Testing stopping the clock",
        }
      end

      it "has error" do
        expect(kase.errors[:stop_the_clock_date]).to eq ["cannot stop prior to last unpause"]
      end
    end
  end
end
