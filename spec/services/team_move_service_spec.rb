require "rails_helper"

describe TeamMoveService do
  let(:original_dir) { find_or_create :directorate }
  let(:target_dir) { find_or_create :directorate }
  let(:responder) { create(:foi_responder, responding_teams: [business_unit]) }

  let(:service) { described_class.new(business_unit, target_dir) }
  let(:business_unit) do
    find_or_create(
      :business_unit,
      name: "Business Unit name",
      directorate: original_dir,
      code: "ABC",
    )
  end
  let(:params) do
    ActiveSupport::HashWithIndifferentAccess.new(
      {
        "full_name" => "Bob Dunnit",
        "email" => "bd@moj.com",
      },
    )
  end

  let(:second_user_service) { UserCreationService.new(team: business_unit, params:) }
  let!(:kase) do
    create(
      :case_being_drafted,
      responding_team: business_unit,
      responder:,
    )
  end
  let!(:klosed_kase) do
    create(
      :closed_case,
      responding_team: business_unit,
      responder:,
    )
  end

  describe "#initialize" do
    it "returns error when the team is not a business unit" do
      expect {
        described_class.new(original_dir, target_dir)
      }.to raise_error TeamMoveService::TeamNotBusinessUnitError,
                       "Cannot move a team which is not a Business Unit"
    end

    it "returns error when the target directorate is not a directorate" do
      expect {
        described_class.new(business_unit, business_unit)
      }.to raise_error TeamMoveService::InvalidDirectorateError,
                       "Cannot move a Business Unit to a team that is not a Directorate"
    end

    it "returns error for the original directorate" do
      expect {
        described_class.new(business_unit, original_dir)
      }.to raise_error TeamMoveService::OriginalDirectorateError,
                       "Cannot move to the original Directorate"
    end

    it "requires a business unit and a target directorate" do
      expect(service.instance_variable_get(:@team)).to eq business_unit
      expect(service.instance_variable_get(:@directorate)).to eq target_dir
      expect(service.instance_variable_get(:@result)).to eq :incomplete
    end
  end

  describe "#call" do
    context "when moving a business unit to another directorate" do
      it "creates a copy of the team in the target directorate" do
        service.call

        expect(service.new_team.directorate).to eq target_dir
      end

      it "moves team users to the new team" do
        expect(business_unit.users).to match_array [responder]
        service.call

        expect(service.new_team.users).to match_array [responder]
      end

      it "does not remove them from the original team" do
        second_user_service.call
        retained_user_roles = business_unit.user_roles.as_json.map { |ur| [ur["team_id"], ur["user_id"], ur["role"]] }
        service.call
        new_user_roles = business_unit.reload.user_roles.as_json.map { |ur| [ur["team_id"], ur["user_id"], ur["role"]] }
        expect(new_user_roles).to include retained_user_roles[0]
        expect(new_user_roles).to include retained_user_roles[1]
      end

      it "sets old team to deleted" do
        service.call

        expect(business_unit.reload.deleted_at).not_to be_nil
      end

      it "sets new team to moved and showing the original team name" do
        service.call

        expect(service.new_team).to eq business_unit.moved_to_unit
        expect(service.new_team.name).to eq business_unit.original_team_name
      end

      it "moves properties to the new team" do
        properties = business_unit.properties.pluck :id
        service.call

        expect(service.new_team.properties.pluck(:id)).to match_array properties
      end

      it "moves correspondence type roles to the new team" do
        correspondence_type_roles = business_unit.correspondence_type_roles.pluck :id
        service.call

        expect(service.new_team.correspondence_type_roles.pluck(:id)).to match_array correspondence_type_roles
      end

      it "ensures the new team has the same code as the old team" do
        code = business_unit.code
        service.call

        expect(service.new_team.code).to eq code
      end

      context "when the team being moved has open cases" do
        it "moves open cases to the new team and removes them from the original team" do
          expect(business_unit.open_cases.first).to eq kase
          service.call

          expect(business_unit.open_cases).to be_empty
          expect(service.new_team.open_cases.first).to eq kase
        end

        it "moves all transitions of the open case to the new team" do
          service.call

          # using factory :case_being_drafted, the case has TWO transitions,
          # One for the transition to drafted,
          # and one for the current _being drafted_ state (in the second, the target team is nill)
          expect(kase.transitions.second.target_team_id).to eq service.new_team.id
          expect(kase.transitions.third.acting_team_id).to eq service.new_team.id
        end
      end

      context "when the team being moved has closed cases" do
        it "leaves closed cases with the original team" do
          expect(business_unit.cases.closed.first).to eq klosed_kase
          service.call

          expect(service.new_team.cases.closed).to be_empty
          expect(business_unit.cases.closed.first).to eq klosed_kase
        end
      end

      context "when the team being moved has a code defined" do
        it "sets the deleted team code to WHATEVER-OLD" do
          code = business_unit.code
          service.call

          expect(business_unit.reload.code).to eq "#{code}-OLD-#{business_unit.id}"
          expect(service.new_team.code).to eq code
        end
      end

      context "when the team being moved has no code defined" do
        it "leaves the team code blank" do
          business_unit.update_attribute(:code, nil)
          service.call

          expect(business_unit.reload.code).to be_blank
          expect(service.new_team.code).to be_blank
        end
      end

      context "when the team being moved has trigger cases" do
        let(:kase) do
          create(
            :case_being_drafted, :flagged,
            responding_team: business_unit,
            responder:
          )
        end

        it "leaves the approving teams as Disclosure" do
          expect(kase.approving_teams).to eq [BusinessUnit.dacu_disclosure]
          service.call

          expect(kase.reload.approving_teams).to eq [BusinessUnit.dacu_disclosure]
        end
      end

      context "when the team being moved has responded cases" do
        let(:responded_kase) do
          create(
            :responded_case,
            responding_team: business_unit,
            responder:,
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
          expect(service.new_team.cases).to match_array [
            kase,
            responded_kase,
          ]
        end
      end

      context "when the team being moved is an approver team" do
        let(:kase) { create(:responded_ico_foi_case) }
        let(:disclosure_team) { BusinessUnit.dacu_disclosure }
        let(:business_unit) { disclosure_team }
        let(:disclosure_user) { disclosure_team.users.first }

        it "moves approver assignments to new team and users are preserved" do
          create :case_transition_respond_to_ico, case: kase
          kase.assignments.create!(team: disclosure_team, user: disclosure_user, role: "approving")
          assignments = kase.approver_assignments.for_team(BusinessUnit.dacu_disclosure)

          existing_approver_assignments_count = assignments.count
          expect(assignments.first.user).to eq disclosure_user
          expect(assignments.count).to eq existing_approver_assignments_count
          expect(disclosure_user.approving_team).to eq business_unit

          service.call

          disclosure_user.reload
          assignments = kase.approver_assignments.for_team(BusinessUnit.dacu_disclosure)
          expect(assignments.first.user).to eq disclosure_user
          expect(assignments.count).to eq existing_approver_assignments_count
          expect(disclosure_user.teams).to match_array [business_unit, service.new_team]
          expect(disclosure_user.approving_team).to eq service.new_team
        end
      end

      context "when the team being moved has invalid team roles" do
        let(:disclosure_team) { BusinessUnit.dacu_disclosure }
        let(:new_user) { create(:user) }
        let(:business_unit) { disclosure_team }

        it "restores all valid users for old team" do
          # add a defective user role and a valid user role
          disclosure_team.user_roles << TeamsUsersRole.new(user_id: nil, role: "responder")
          disclosure_team.user_roles << TeamsUsersRole.new(user_id: new_user.id, role: "responder")
          user_count = disclosure_team.users.count

          service.call

          expect(disclosure_team.reload.users.count).to eq user_count
          expect(disclosure_team.reload.users.last).to eq new_user
        end
      end
    end
  end
end
