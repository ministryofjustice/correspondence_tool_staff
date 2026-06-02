require "rails_helper"

describe CaseAutoCloseService do
  # Freeze time so tests are not affected by the passage of real calendar time.
  # All stopped dates below are expressed relative to this fixed reference point.
  # Reference: 2024-06-01
  #   91 days prior = 2024-03-02  (> threshold → eligible for auto-close)
  #   90 days prior = 2024-03-03  (= threshold → NOT eligible for auto-close)
  around do |example|
    Timecop.freeze(Time.zone.local(2024, 6, 1)) { example.run }
  end

  def create_stopped_sar(stopped_date:)
    kase = create(:sar_case)

    create(:case_transition_stop_the_clock, case: kase, details: {
      stop_the_clock_categories: ["Category 1 - Sub Category"],
      stop_the_clock_reason: "Stopped for testing",
      stop_the_clock_date: stopped_date,
      last_status: kase.current_state,
    })

    kase.reload
  end

  describe ".call" do
    context "when not dry-run (dryrun: false)" do
      # 91 days stopped — strictly over the 90-day threshold
      let!(:kase_just_over_threshold) { create_stopped_sar(stopped_date: Date.new(2024, 3, 2)) }
      # 152 days stopped — well over threshold
      let!(:kase_well_over_threshold) { create_stopped_sar(stopped_date: Date.new(2024, 1, 1)) }
      # Exactly 90 days stopped — equals threshold, NOT eligible
      let!(:kase_at_threshold) { create_stopped_sar(stopped_date: Date.new(2024, 3, 3)) }
      # 31 days stopped — below threshold, NOT eligible
      let!(:kase_below_threshold) { create_stopped_sar(stopped_date: Date.new(2024, 5, 1)) }

      before { described_class.call(dryrun: false) }

      it "auto-closes cases stopped for more than #{Settings.auto_close_stopped_threshold} days" do
        expect(kase_just_over_threshold.reload.current_state).to eq("closed")
        expect(kase_well_over_threshold.reload.current_state).to eq("closed")
      end

      it "does not auto-close cases stopped for #{Settings.auto_close_stopped_threshold} days or fewer" do
        expect(kase_at_threshold.reload.current_state).to eq("stopped")
        expect(kase_below_threshold.reload.current_state).to eq("stopped")
      end
    end

    context "when dry-run (dryrun: true)" do
      # 91 days stopped — would be eligible for auto-close but dry-run must not act
      let!(:kase_prolonged) { create_stopped_sar(stopped_date: Date.new(2024, 3, 2)) }

      it "does not change the state of eligible cases" do
        expect {
          described_class.call(dryrun: true)
        }.not_to(change { kase_prolonged.reload.current_state })
      end
    end
  end
end
