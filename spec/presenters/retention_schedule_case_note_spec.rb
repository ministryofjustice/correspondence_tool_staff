require "rails_helper"

RSpec.describe RetentionScheduleCaseNote do
  describe ".new" do
    it "is a private method" do
      expect(described_class.respond_to?(:new)).to eq(false)
    end
  end

  describe ".log!" do
    let(:kase) { instance_double(Case::Base, state_machine: sm_double) }
    let(:user) { instance_double(User) }
    let(:team) { "Team XYZ" }

    let(:sm_double) { double("StateMachine") } # rubocop:disable RSpec/VerifiedDoubles
    let(:args) { { kase:, user:, changes: } }

    before do
      allow(user).to receive(:case_team).and_return(team)
    end

    context "when there are no changes" do
      let(:changes) { {} }

      it "does not write anything to the case history" do
        expect(sm_double).not_to receive(:annotate_retention_changes!)
        described_class.log!(args)
      end
    end

    context "when there are changes only in the `state` attribute" do
      let(:changes) { { state: %i[not_set review] } }

      it "writes the change to the case history" do
        expect(
          sm_double,
        ).to receive(:annotate_retention_changes!).with(
          acting_user: user, acting_team: team,
          message: "Retention status changed from Not set to Review"
        )

        described_class.log!(args)
      end
    end

    context "when there are changes only in the `planned_destruction_date` attribute" do
      let(:changes) { { planned_destruction_date: [Date.new(2018, 10, 25), Date.new(2025, 12, 31)] } }

      it "writes the change to the case history" do
        expect(
          sm_double,
        ).to receive(:annotate_retention_changes!).with(
          acting_user: user, acting_team: team,
          message: "Destruction date changed from 25-10-2018 to 31-12-2025"
        )

        described_class.log!(args)
      end
    end

    context "when there are changes in both attributes" do
      let(:changes) { { state: %i[not_set review], planned_destruction_date: [Date.new(2018, 10, 25), Date.new(2025, 12, 31)] } }

      it "writes the change to the case history" do
        expect(
          sm_double,
        ).to receive(:annotate_retention_changes!).with(
          acting_user: user, acting_team: team,
          message: "Retention status changed from Not set to Review\nDestruction date changed from 25-10-2018 to 31-12-2025"
        )

        described_class.log!(args)
      end
    end

    context "when a system update" do
      let(:changes) { { state: [nil, :not_set], planned_destruction_date: [nil, Date.new(2025, 12, 31)] } }

      it "writes the system change to the case history" do
        expect(
          sm_double,
        ).to receive(:annotate_system_retention_changes!).with(
          acting_user: user, acting_team: team,
          message: "Destruction date set to 31-12-2025"
        )

        described_class.log!(**args, is_system: true)
      end
    end
  end
end
