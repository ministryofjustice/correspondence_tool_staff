require 'rails_helper'

describe UserCreationService do

  describe '#call' do

    let(:params) do
      HashWithIndifferentAccess.new(
        {
          'full_name' => 'Danny Driver',
          'email' => 'dd@moj.com'
        }
      )
    end

    let(:service)  { UserCreationService.new(team: @team, params: params) }

    before(:all) do
      @team = create :responding_team, name: 'User Creation Team'
    end

    after(:all) { DbHousekeeping.clean }

    context 'when no existing user exists' do

      context 'valid' do
        it 'creates a user' do
          expect{
            service.call
          }.to change{ User.count }.by(1)
          expect(User.last.full_name).to eq 'Danny Driver'
          expect(User.last.email).to eq 'dd@moj.com'
        end

        it 'creates the team_user_role record' do
          expect { service.call }.to change{ TeamsUsersRole.count }.by(1)
          expect(User.last.team_roles.size).to eq 1
          tr = User.last.team_roles.singular
          expect(tr.team_id).to eq @team.id
          expect(tr.role).to eq 'responder'
        end

        it 'returns ok' do
          service.call
          expect(service.result).to eq :ok
        end

      end
      context 'invalid' do
        it 'returns :error' do
          params[:email] = ''
          service.call
          expect(service.result).to eq :error
          expect(service.user.errors[:email]).to eq ["can't be blank"]
        end
      end
    end

    context 'the user already exists in this team' do
      before(:all) do
        @existing_user = User.new(full_name: 'danny driver', email: 'dd@moj.com', password: 'kjkjkj')
        @existing_user.team_roles << TeamsUsersRole.new(team: @team, role: 'responder')
        @existing_user.save!
      end

      after(:all) do
        User.find_by_email!('dd@moj.com').destroy
      end

      it 'returns :error' do
        service.call
        expect(service.result).to eq :error
      end

      it 'sets a base error on the user model' do
        service.call
        expect(service.user.errors[:base]).to eq ['This user is already in the team']
      end

      it 'does not create a new user record' do
        expect { service.call }.not_to change{ User.count }
      end

      it 'does not creae a new TeamsUsersRole record' do
        expect{ service.call }.not_to change{ TeamsUsersRole.count }
      end

    end

    context 'when a user with the same email exists' do
      before(:each) do
        team_2 = BusinessUnit.create(name: 'UCT 2', parent_id: @team.parent_id, role: 'responder')
        @existing_user = User.new(full_name: 'danny driver', email: 'dd@moj.com', password: 'kjkjkj')
        @existing_user.team_roles << TeamsUsersRole.new(team: team_2, role: 'responder')
        @existing_user.save!
      end

      context 'when the names match' do

        it 'does not create a new user record' do
          expect { service.call }.not_to change{ User.count }
        end

        it 'creates a team_user_role record' do
          expect{ service.call }.to change{ TeamsUsersRole.count }.by(1)
          expect(@existing_user.reload.team_roles.size).to eq 2
          tr = @existing_user.team_roles.last
          expect(tr.team_id).to eq @team.id
          expect(tr.role).to eq 'responder'
        end

        it 'returns existing_ok' do
          service.call
          expect(service.result).to eq :existing_ok
        end
      end

      context 'names match but different role' do
        before do
          approving_team = create :approving_team
          @existing_user.team_roles.clear
          @existing_user.team_roles << TeamsUsersRole.new(team: approving_team,
                                                          role: 'approver')
        end

        it 'it returns existing_ok' do
          service.call
          expect(service.result).to eq :existing_ok
        end

        it 'creates a team_user_role record' do
          expect{ service.call }.to change{ TeamsUsersRole.count }.by(1)
          expect(@existing_user.reload.team_roles.size).to eq 2
          tr = @existing_user.team_roles.last
          expect(tr.team_id).to eq @team.id
          expect(tr.role).to eq 'responder'
        end

      end

      context 'when names mismatch' do
        before(:each) {
          @existing_user.reload.update!(full_name: 'Stephen Richards')
        }

        it 'does not create a new user record' do
          service.call
          expect { service.call }.not_to change{ User.count }
        end

        it 'sets a base error on the user model' do
          service.call
          expect(service.user.errors[:base]).to eq ['An existing user with this email address already exists with the name: Stephen Richards']
        end

        it 'returns :existing_user_name_mismatch' do
          service.call
          expect(service.result).to eq :error
        end
      end
    end
  end


end
