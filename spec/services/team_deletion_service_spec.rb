require "rails_helper"

describe TeamDeletionService do
  describe "#call" do
    context "when deleting a directorate or business group" do
      let(:dir)     { find_or_create :directorate }
      let(:service) { described_class.new(dir) }

      context "and child team is not active" do
        let(:time) { Time.zone.local(2017, 6, 30, 12, 0, 0) }

        before do
          find_or_create(:business_unit, :deactivated, directorate: dir)
        end

        it "updates the team name" do
          Timecop.freeze(time) do
            service.call
            expect(dir.reload.name).to include Team::DEACTIVATED_LABEL, dir.name
          end
        end

        it "updates the deleted_at column" do
          Timecop.freeze(time) do
            service.call
            expect(dir.reload.deleted_at).to eq time
          end
        end
      end

      context "and child team is active" do
        before do
          find_or_create(:business_unit, directorate: dir)
        end

        it "does not change the name" do
          service.call
          expect(dir.reload.name).not_to include "DEACTIVATED"
        end

        it "does not update the deleted_at column" do
          service.call
          expect(dir.reload.deleted_at).to be nil
        end
      end

      context "and deleting a business unit" do
        let(:bu_without_users) { create :responding_team, responders: [] }
        let(:bu_with_users)    { create :responding_team }

        context "and no cases, no users" do
          it "returns :ok and soft deletes the business unit" do
            expect(bu_without_users.open_cases).to be_empty
            expect(bu_without_users.users).to be_empty
            expect(bu_without_users.deleted_at).to be_nil

            service = described_class.new(bu_without_users)
            service.call

            expect(service.result).to eq :ok
            expect(bu_without_users.deleted_at).not_to be_nil
            expect(bu_without_users.name).to start_with(Team::DEACTIVATED_LABEL)
          end
        end

        context "and has open cases" do
          it "returns :error with message in team errors array" do
            create :assigned_case, responding_team: bu_without_users
            expect(bu_without_users.users).to be_empty
            expect(bu_without_users.open_cases).not_to be_empty

            service = described_class.new(bu_without_users)
            service.call

            expect(service.result).to eq :error
            expect(bu_without_users.errors[:base]).to eq ["Unable to deactivate: this business unit has open cases"]
            expect(bu_without_users.deleted_at).to be_nil
          end
        end

        context "and has closed cases but no open" do
          it "returns :ok and soft deletes the team" do
            DbHousekeeping.clean(seed: true)
            closed_case = create :closed_case
            bu = closed_case.responding_team
            bu.responders.destroy_all

            expect(bu.cases).not_to be_empty
            expect(bu.open_cases).to be_empty

            bu.responders.destroy_all
            service = described_class.new(bu)
            service.call

            expect(service.result).to eq :ok
            expect(bu.deleted_at).not_to be_nil
            expect(bu.name).to start_with(Team::DEACTIVATED_LABEL)
          end
        end
      end
    end
  end
end
