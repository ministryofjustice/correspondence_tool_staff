require "rails_helper"

describe TeamJoinService do
  let(:original_joining_team) { create(:responding_team, name: "Joining Team") }
  let(:kase) { create :case_being_drafted, responding_team: business_unit, responder: joining_team_user }
  let(:klosed_kase) { create :closed_case, responding_team: business_unit, responder: joining_team_user }
  let(:original_target_team) { create(:responding_team, name: "Target Team") }
  let(:joining_team_move_service) { TeamMoveService.new(original_joining_team, target_dir) }
  let(:target_team_move_service) { TeamMoveService.new(original_target_team, target_dir) }
  let(:business_unit) { joining_team_move_service.new_team }
  let(:target_business_unit) { target_team_move_service.new_team }
  let(:target_dir) { find_or_create :directorate }
  let(:disclosure_team) { find_or_create(:team_disclosure) }
  let(:service) { described_class.new(business_unit, target_business_unit) }

  let!(:joining_team_user) { original_joining_team.responders.first }
  let!(:target_team_user) { original_target_team.responders.first }

  before do
    joining_team_move_service.call
    target_team_move_service.call
    kase
    klosed_kase
  end

  describe "#initialize" do
    it "returns error when the team joining has a special role" do
      expect {
        described_class.new(disclosure_team, business_unit)
      }.to raise_error TeamJoinService::TeamHasCodeError,
                       "Cannot join a Business Unit that has a code defined"
    end

    it "returns error when the team being joined has a special role" do
      expect {
        described_class.new(business_unit, disclosure_team)
      }.to raise_error TeamJoinService::TeamHasCodeError,
                       "Cannot join a Business Unit that has a code defined"
    end

    it "returns error when the team is not a business unit" do
      expect {
        described_class.new(business_unit.directorate, target_business_unit)
      }.to raise_error TeamJoinService::TeamNotBusinessUnitError,
                       "Cannot join a team which is not a Business Unit"
    end

    it "returns error when the target team is not a team" do
      expect {
        described_class.new(business_unit, business_unit.directorate)
      }.to raise_error TeamJoinService::InvalidTargetBusinessUnitError,
                       "Cannot join a Business Unit to a team that is not a Business Unit"
    end

    it "returns error for the original team" do
      expect {
        described_class.new(business_unit, business_unit)
      }.to raise_error TeamJoinService::OriginalBusinessUnitError,
                       "Cannot join a Business Unit to itself"
    end

    it "requires a business unit and a target business unit" do
      expect(service.instance_variable_get(:@team)).to eq business_unit
      expect(service.instance_variable_get(:@target_team)).to eq target_business_unit
      expect(service.instance_variable_get(:@result)).to eq :incomplete
    end
  end

  describe "#call" do
    context "when joining a business unit into another business unit" do
      it "joins users to new team history" do
        service.call
        expect(business_unit.reload.users).to match_array [joining_team_user, target_team_user]
        expect(service.target_team.users).to match_array [joining_team_user, target_team_user]
        expect(joining_team_user.reload.teams).to match_array [
          target_business_unit,
          business_unit,
          original_joining_team,
          original_target_team,
        ]
      end

      it "gives the target team the old team history" do
        service.call
        expect(target_team_user.reload.teams).to match_array [
          target_business_unit,
          business_unit,
          original_joining_team,
          original_target_team,
        ]
      end

      it "sets old team to deleted" do
        sleep 1
        service.call
        expect(business_unit.reload.deleted_at).not_to be_nil
      end

      it "links the old team to the new team" do
        service.call
        expect(service.target_team).to eq business_unit.moved_to_unit
      end

      context "when the team being moved has open cases" do
        it "joins open cases to the new team and removes them from the original team" do
          expect(business_unit.open_cases.first).to eq kase
          service.call
          expect(business_unit.open_cases).to be_empty
          expect(service.target_team.open_cases.first).to eq kase
        end

        it "joins all transitions of the open case to the new team" do
          service.call

          # using factory :case_being_drafted, the case has TWO transitions,
          # One for the transition to drafted,
          # and one for the current _being drafted_ state (in the second, the target team is nill)
          expect(kase.transitions.second.target_team_id).to eq service.target_team.id
          expect(kase.transitions.third.acting_team_id).to eq service.target_team.id
        end
      end

      context "when the team being moved has closed cases" do
        it "leaves closed cases with the original team" do
          expect(business_unit.cases.closed.first).to eq klosed_kase
          service.call
          expect(service.target_team.cases.closed).to be_empty
          expect(business_unit.cases.closed.first).to eq klosed_kase
        end
      end

      context "when the team being moved has responded cases" do
        let(:responded_kase) do
          create(
            :responded_case,
            responding_team: business_unit,
            responder: joining_team_user,
          )
        end

        it "moves the open and responded cases" do
          expect(business_unit.cases).to match_array [
            kase,
            klosed_kase,
            responded_kase,
          ]
          service.call
          expect(business_unit.cases.reload).to match_array [klosed_kase]
          expect(service.target_team.cases).to match_array [
            kase,
            responded_kase,
          ]
        end
      end

      context "when the team being moved has trigger cases" do
        let(:kase) do
          create(
            :case_being_drafted, :flagged,
            responding_team: business_unit,
            responder: joining_team_user
          )
        end

        it "leaves the approving teams as Disclosure" do
          expect(kase.approving_teams).to eq [BusinessUnit.dacu_disclosure]
          service.call
          expect(kase.reload.approving_teams).to eq [BusinessUnit.dacu_disclosure]
        end
      end
    end
  end
end
