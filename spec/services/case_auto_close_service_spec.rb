require "rails_helper"

describe CaseAutoCloseService do
  describe ".call" do
    let(:kase1) { create(:sar_case) }
    let(:kase2) { create(:sar_case) }
    let(:kase3) { create(:sar_case) }
    let(:user) { find_or_create :manager_approver }

    before do
      test_cases = [(3.months + 1.day).ago, 3.months.ago, 2.months.ago]

      [kase1, kase2, kase3].each_with_index do |kase, index|
        kase.state_machine.stop_the_clock!(
          acting_user: user,
          acting_team: user.case_team(kase),
          message: "Testing auto-close",
          details: { stop_the_clock_date: test_cases[index] },
        )
      end
    end

    context "when not dry-run" do
      it "closes cases that have been stopped for 3 months or more" do
        described_class.call(dryrun: false)

        expect(kase1.reload.current_state).to eq("closed")
        expect(kase2.reload.current_state).to eq("stopped")
        expect(kase3.reload.current_state).to eq("stopped")
      end
    end

    context "when dry-run" do
      it "does not close cases that have been stopped for 3 months or more" do
        described_class.call(dryrun: true)

        expect(kase1.reload.current_state).to eq("stopped")
        expect(kase2.reload.current_state).to eq("stopped")
        expect(kase3.reload.current_state).to eq("stopped")
      end
    end
  end
end
