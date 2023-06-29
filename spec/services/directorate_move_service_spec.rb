require "rails_helper"

describe DirectorateMoveService do
  let(:original_dir) { find_or_create :business_group }
  let(:target_dir) { find_or_create :business_group }
  let(:responder) { create(:foi_responder, responding_teams: [business_unit]) }

  let(:service) { described_class.new(directorate, target_dir) }
  let(:directorate) do
    find_or_create(
      :directorate,
      name: "Directorate name",
      business_group: original_dir,
    )
  end
  let(:business_unit) do
    find_or_create(
      :business_unit,
      name: "Business Unit name",
      directorate:,
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
    it "returns error when the team is not a directorate" do
      expect {
        described_class.new(business_unit, target_dir)
      }.to raise_error DirectorateMoveService::NotDirectorateError,
                       "Cannot move a team which is not a Directorate"
    end

    it "returns error when the target directorate is not a directorate" do
      expect {
        described_class.new(directorate, directorate)
      }.to raise_error DirectorateMoveService::InvalidBusinessGroupError,
                       "Cannot move a Directorate to a team that is not a Business Group"
    end

    it "returns error for the original business group" do
      expect {
        described_class.new(directorate, original_dir)
      }.to raise_error DirectorateMoveService::OriginalBusinessGroupError,
                       "Cannot move to the original Business Group"
    end

    it "requires a business unit and a target directorate" do
      expect(service.instance_variable_get(:@directorate)).to eq directorate
      expect(service.instance_variable_get(:@business_group)).to eq target_dir
      expect(service.instance_variable_get(:@result)).to eq :incomplete
    end
  end

  describe "#call" do
    context "when moving a directorate to another business group" do
      it "creates a copy of the team in the new copy of directorate under target business group" do
        service.call
        service.new_teams.each do |new_team|
          expect(new_team.directorate).to eq service.new_directorate
        end
      end

      it "creates a copy of the directorate in the target business_group" do
        service.call

        expect(service.new_directorate.business_group).to eq target_dir
      end

      it "moves team users to the new team" do
        expect(business_unit.users).to match_array [responder]
        service.call

        expect(service.new_teams.first.users).to match_array [responder]
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

      it "sets old directorate to deleted" do
        service.call

        expect(directorate.reload.deleted_at).not_to be_nil
      end

      it "sets new directorate to moved and showing the original directorate name" do
        service.call

        expect(service.new_directorate).to eq directorate.moved_to_unit
        expect(service.new_directorate.name).to eq directorate.original_team_name
      end

      it "sets new team to moved and showing the original team name" do
        service.call
        business_unit.reload
        expect(service.new_teams.first).to eq business_unit.moved_to_unit
        expect(service.new_teams.first.name).to eq business_unit.original_team_name
      end

      it "moves properties to the new directorate" do
        properties = directorate.properties.pluck :id
        service.call

        expect(service.new_directorate.properties.pluck(:id)).to match_array properties
      end

      it "moves properties to the new team" do
        properties = business_unit.properties.pluck :id
        service.call

        expect(service.new_teams.first.properties.pluck(:id)).to match_array properties
      end

      it "moves correspondence type roles to the new team" do
        correspondence_type_roles = business_unit.correspondence_type_roles.pluck :id
        service.call

        expect(service.new_teams.first.correspondence_type_roles.pluck(:id)).to match_array correspondence_type_roles
      end

      it "ensures the new team has the same code as the old team" do
        code = business_unit.code
        service.call

        expect(service.new_teams.first.code).to eq code
      end

      context "when the team being moved has open cases" do
        it "moves open cases to the new team and removes them from the original team" do
          expect(business_unit.open_cases.first).to eq kase
          service.call

          expect(business_unit.open_cases).to be_empty
          expect(service.new_teams.first.open_cases.first).to eq kase
        end

        it "moves all transitions of the open case to the new team" do
          service.call

          # using factory :case_being_drafted, the case has TWO transitions,
          # One for the transition to drafted,
          # and one for the current _being drafted_ state (in the second, the target team is nill)
          expect(kase.transitions.second.target_team_id).to eq service.new_teams.first.id
          expect(kase.transitions.third.acting_team_id).to eq service.new_teams.first.id
        end
      end

      context "when the team being moved has closed cases" do
        it "leaves closed cases with the original team" do
          expect(business_unit.cases.closed.first).to eq klosed_kase
          service.call

          expect(service.new_teams.first.cases.closed).to be_empty
          expect(business_unit.cases.closed.first).to eq klosed_kase
        end
      end

      context "when the team being moved has a code defined" do
        it "sets the deleted team code to WHATEVER-OLD" do
          code = business_unit.code
          service.call

          expect(business_unit.reload.code).to eq "#{code}-OLD-#{business_unit.id}"
          expect(service.new_teams.first.code).to eq code
        end
      end

      context "when the team being moved has no code defined" do
        it "leaves the team code blank" do
          business_unit.update!(code: nil)
          service.call

          expect(business_unit.reload.code).to be_blank
          expect(service.new_teams.first.code).to be_blank
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
          expect(service.new_teams.first.cases).to match_array [
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

          this_service = described_class.new(business_unit.directorate, target_dir)
          this_service.call
          business_unit.reload
          disclosure_user.reload
          assignments = kase.approver_assignments.for_team(BusinessUnit.dacu_disclosure)
          expect(assignments.first.user).to eq disclosure_user
          expect(assignments.count).to eq existing_approver_assignments_count
          expect(this_service.new_teams).to include disclosure_user.approving_team
          expect(disclosure_user.teams).to match_array [business_unit, disclosure_user.approving_team]
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
