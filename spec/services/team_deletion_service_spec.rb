require 'rails_helper'

describe TeamDeletionService do

  describe '#call' do

    context 'deleting a directorate or business group' do
      let(:dir)           { find_or_create :directorate }
      let(:service)       { TeamDeletionService.new(dir) }

      context 'child team is not active' do
        let(:time) { Time.new(2017, 6, 30, 12, 0, 0) }
        let!(:bu) { find_or_create(:business_unit, :deactivated, directorate: dir) }

        it 'updates the team name' do
          Timecop.freeze(time) do
            service.call
            expect(dir.reload.name).to include "DEACTIVATED", dir.name
          end
        end

        it 'updates the deleted_at column' do
          Timecop.freeze(time) do
            service.call
            expect(dir.reload.deleted_at).to eq time
          end
        end
      end

      context 'child team is active' do
        let!(:bu) { find_or_create(:business_unit, directorate: dir) }
        it 'does not change the name' do
          service.call
          expect(dir.reload.name).not_to include "DEACTIVATED"
        end

        it 'does not update the deleted_at column' do
          service.call
          expect(dir.reload.deleted_at).to be nil
        end
      end

      context 'deleting a business unit' do
        let(:bu_without_users)        { create :responding_team, responders: [] }
        let(:bu_with_users)           { create :responding_team }

        context 'no cases, no users' do
          it 'returns :ok and soft deletes the business unit' do
            expect(bu_without_users.open_cases).to be_empty
            expect(bu_without_users.users).to be_empty
            expect(bu_without_users.deleted_at).to be_nil

            service = TeamDeletionService.new(bu_without_users)
            service.call

            expect(service.result).to eq :ok
            expect(bu_without_users.deleted_at).not_to be_nil
            expect(bu_without_users.name).to match(/^DEACTIVATED/)
          end
        end

        context 'has users' do
          it 'returns :error with error in team' do
            expect(bu_with_users.users).not_to be_empty
            expect(bu_with_users.deleted_at).to be_nil

            service = TeamDeletionService.new(bu_with_users)
            service.call

            expect(service.result).to eq :error
            expect(bu_with_users.errors[:base]).to eq ['Unable to deactivate: this business unit has team members']
            expect(bu_with_users.deleted_at).to be_nil
            expect(bu_with_users.name).not_to match(/^DEACTIVATED/)
          end
        end

        context 'has open cases' do
          it 'returns :error with message in team errors array' do
            create :assigned_case, responding_team: bu_without_users
            expect(bu_without_users.users).to be_empty
            expect(bu_without_users.open_cases).not_to be_empty

            service = TeamDeletionService.new(bu_without_users)
            service.call

            expect(service.result).to eq :error
            expect(bu_without_users.errors[:base]).to eq ['Unable to deactivate: this business unit has open cases']
            expect(bu_without_users.deleted_at).to be_nil
          end
        end

        context 'has closed cases but no open' do
          it 'returns :ok and soft deletes the team' do
            create :closed_case, responding_team: bu_without_users
            expect(bu_without_users.cases).not_to be_empty
            expect(bu_without_users.open_cases).to be_empty

            service = TeamDeletionService.new(bu_without_users)
            service.call

            expect(service.result).to eq :ok
            expect(bu_without_users.deleted_at).not_to be_nil
            expect(bu_without_users.name).to match(/^DEACTIVATED/)
          end
        end
      end
    end

  end
end
