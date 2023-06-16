require "rails_helper"

describe TeamFinderService do
  # teams
  let(:team_bmt)                    { find_or_create :team_disclosure_bmt }
  let(:team_disclosure)             { find_or_create :team_disclosure }
  let(:team_candi)                  { create :responding_team, name: "Candi" }
  let(:other_team)                  { create :responding_team, name: "Other responding team" }

  # users
  let(:responder)                   { create :responder, responding_teams: [team_candi] }
  let(:other_responder)             { create :responder, responding_teams: [team_candi] }
  let(:multi_role_user) do
    create :user,
           managing_teams: [team_bmt],
           approving_team: team_disclosure,
           responding_teams: [team_candi]
  end
  let(:disclosure_specialist)       { find_or_create :disclosure_specialist }
  let(:other_approver)              { create :user, approving_team: team_disclosure }

  # cases
  let(:kase) do
    create :case_with_response, :flagged_accepted,
           responding_team: team_candi,
           responder:,
           approving_team: team_disclosure,
           approver: disclosure_specialist
  end

  let(:multi_role_managed_case) do
    create :case_with_response, :flagged_accepted,
           responding_team: team_candi,
           responder: multi_role_user,
           approving_team: team_disclosure,
           approver: multi_role_user
  end

  let(:other_responder_case) { create :case_with_response, responder: other_responder }

  describe "#team_for_assigned_user" do
    context "no such assignment with specified user" do
      it "raises" do
        expect {
          described_class.new(kase, other_responder, :approver).team_for_assigned_user
        }.to raise_error TeamFinderService::UserNotFoundError,
                         "No accepted assignment with role 'approving' for user #{other_responder.id} on case #{kase.id}"
      end
    end

    context "assignment with user exists, but not for specified role" do
      it "raises" do
        expect {
          described_class.new(kase, disclosure_specialist, :responder).team_for_assigned_user
        }.to raise_error TeamFinderService::UserNotFoundError,
                         "No accepted assignment with role 'responding' for user #{disclosure_specialist.id} on case #{kase.id}"
      end
    end

    context "assignment with user exists for specified role, but not accepted" do
      it "raises" do
        assignment = kase.assignments.responding.accepted.first
        assignment.update!(state: "pending")
        expect {
          described_class.new(kase, responder, :responder).team_for_assigned_user
        }.to raise_error TeamFinderService::UserNotFoundError,
                         "No accepted assignment with role 'responding' for user #{responder.id} on case #{kase.id}"
      end
    end

    context "accepted assignment for user with specified role exists" do
      it "returns the team" do
        team = described_class.new(kase, responder, :responder).team_for_assigned_user
        expect(team).to eq team_candi
      end
    end

    context "any assignment for user with specified role exists" do
      it "returns the team even if kase rejected" do
        responder_assignment = kase.assignments.responding.singular
        responder_assignment.update!(state: "rejected", reasons_for_rejection: "just because")
        team = described_class.new(kase, responder, :responder).team_for_user
        expect(team).to eq team_candi
      end
    end

    context "accepted assignment exist for user with multiple roles" do
      it "returns the correct team for the role" do
        user_assignments = multi_role_managed_case
                             .assignments
                             .accepted
                             .where(user_id: multi_role_user.id)
        expect(user_assignments.size).to eq 2
        expect(user_assignments.map(&:team_id))
          .to match_array([team_disclosure.id, team_candi.id])
        team = described_class
                 .new(multi_role_managed_case, multi_role_user, :approver)
                 .team_for_assigned_user
        expect(team).to eq team_disclosure
      end
    end
  end

  describe "#team_for_unassigned_user" do
    context "no assignments on case with specified role" do
      it "raises" do
        responder_assignment = kase.assignments.responding.singular
        responder_assignment.destroy!
        expect {
          described_class.new(kase, responder, :responder).team_for_unassigned_user
        }.to raise_error TeamFinderService::UserNotFoundError,
                         "No accepted assignment with role 'responding' for user #{responder.id} on case #{kase.id}"
      end
    end

    context "assignment exists with the specified role, but is not accepted" do
      it "raises" do
        responder_assignment = kase.assignments.responding.singular
        responder_assignment.update!(state: "rejected", reasons_for_rejection: "just because")
        expect {
          described_class.new(kase, responder, :responder).team_for_unassigned_user
        }.to raise_error TeamFinderService::UserNotFoundError,
                         "No accepted assignment with role 'responding' for user #{responder.id} on case #{kase.id}"
      end
    end

    context "user is member of team that is assigned to case in specified role" do
      it "returns the team" do
        team = described_class.new(kase, other_responder, :responder).team_for_unassigned_user
        expect(team).to eq team_candi
      end
    end

    context "multi-role user is member of team which is assigned to case in specified role" do
      it "returns the team" do
        team = described_class.new(multi_role_managed_case, multi_role_user, :responder).team_for_unassigned_user
        expect(team).to eq team_candi
      end
    end
  end

  context "Invalid team role" do
    it "raises" do
      expect {
        described_class.new("mock_case", "mock_user", :assessor)
      }.to raise_error ArgumentError, "Invalid role"
    end
  end
end
