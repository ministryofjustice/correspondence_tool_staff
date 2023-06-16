require "rails_helper"

describe UserCreationService do
  describe "#call" do
    let(:params) do
      ActiveSupport::HashWithIndifferentAccess.new(
        {
          "full_name" => "Danny Driver",
          "email" => "dd@moj.com",
        },
      )
    end

    let!(:team) { find_or_create :responding_team, name: "User Creation Team" }
    let(:service) { described_class.new(team:, params:) }

    context "when no existing user exists" do
      context "valid" do
        it "creates a user" do
          expect {
            service.call
          }.to change(User, :count).by(1)
          expect(User.last.full_name).to eq "Danny Driver"
          expect(User.last.email).to eq "dd@moj.com"
        end

        it "creates the team_user_role record" do
          expect { service.call }.to change(TeamsUsersRole, :count).by(1)
          expect(User.last.team_roles.size).to eq 1
          tr = User.last.team_roles.singular
          expect(tr.team_id).to eq team.id
          expect(tr.role).to eq "responder"
        end

        it "returns ok" do
          service.call
          expect(service.result).to eq :ok
        end
      end

      context "invalid" do
        it "returns :error" do
          params[:email] = ""
          service.call
          expect(service.result).to eq :error
          expect(service.user.errors[:email]).to eq ["cannot be blank"]
        end
      end
    end

    context "the user already exists in this team" do
      let!(:existing_user) { User.new(full_name: "danny driver", email: "dd@moj.com", password: SecureRandom.random_number(36**13).to_s(36)) }
      let!(:existing_user_role) { existing_user.team_roles << TeamsUsersRole.new(team:, role: "responder") }
      let!(:success) { existing_user.save }

      it "returns :error" do
        service.call
        expect(service.result).to eq :error
      end

      it "sets a base error on the user model" do
        service.call
        expect(service.user.errors[:base]).to eq ["This user is already in the team"]
      end

      it "does not create a new user record" do
        expect { service.call }.not_to change(User, :count)
      end

      it "does not creae a new TeamsUsersRole record" do
        expect { service.call }.not_to change(TeamsUsersRole, :count)
      end
    end

    context "when a user with the same email exists" do
      let!(:other_team) { find_or_create :responding_team, name: "Another User Creation Team" }
      let!(:existing_user) { User.new(full_name: "danny driver", email: "dd@moj.com", password: SecureRandom.random_number(36**13).to_s(36)) }
      let!(:existing_user_role) { existing_user.team_roles << TeamsUsersRole.new(team: other_team, role: "responder") }
      let!(:success) { existing_user.save }

      context "when the names match" do
        it "does not create a new user record" do
          expect { service.call }.not_to change(User, :count)
        end

        it "creates a team_user_role record" do
          expect { service.call }.to change(TeamsUsersRole, :count).by(1)
          expect(existing_user.reload.team_roles.size).to eq 2
          tr = existing_user.team_roles.last
          expect(tr.team_id).to eq team.id
          expect(tr.role).to eq "responder"
        end

        it "returns existing_ok" do
          service.call
          expect(service.result).to eq :existing_ok
        end
      end

      context "names match but different role" do
        before do
          approving_team = create :approving_team
          existing_user.team_roles.clear
          existing_user.team_roles << TeamsUsersRole.new(team: approving_team,
                                                         role: "approver")
        end

        it "returns existing_ok" do
          service.call
          expect(service.result).to eq :existing_ok
        end

        it "creates a team_user_role record" do
          expect { service.call }.to change(TeamsUsersRole, :count).by(1)
          expect(existing_user.reload.team_roles.size).to eq 2
          tr = existing_user.team_roles.last
          expect(tr.team_id).to eq team.id
          expect(tr.role).to eq "responder"
        end
      end

      context "deleted user rejoins the team" do
        before do
          existing_user.reload.update!(deleted_at: Date.yesterday)
          existing_user.team_roles.delete_all
        end

        it "returns existing_ok" do
          service.call
          expect(service.result).to eq :existing_ok
        end

        it "creates a team_user_role record" do
          expect { service.call }.to change(TeamsUsersRole, :count).by(1)
          expect(existing_user.reload.team_roles.size).to eq 1
          tr = existing_user.team_roles.last
          expect(tr.team_id).to eq team.id
          expect(tr.role).to eq "responder"
        end

        it "unlocks their account" do
          service.call
          expect(existing_user.reload.deleted_at).to be_nil
        end
      end

      context "when names mismatch" do
        before do
          existing_user.reload.update!(full_name: "Stephen Richards")
        end

        it "does not create a new user record" do
          service.call
          expect { service.call }.not_to change(User, :count)
        end

        it "sets a base error on the user model" do
          service.call
          expect(service.user.errors[:base]).to eq ["An existing user with this email address already exists with the name: Stephen Richards"]
        end

        it "returns :existing_user_name_mismatch" do
          service.call
          expect(service.result).to eq :error
        end
      end
    end

    context "when the team has previous incarnations" do
      let(:target_dir) { find_or_create :directorate }
      let(:team_move_service) { TeamMoveService.new(team, target_dir) }

      it "joins the user to both the current and previous teams" do
        # move the team being joined first
        team_move_service.call
        new_team = team_move_service.new_team

        # add a new user to the new team
        service = described_class.new(team: new_team, params:)
        service.call
        expect(service.result).to eq :ok
        expect(User.last.teams).to match_array [team, new_team]
      end
    end
  end
end
