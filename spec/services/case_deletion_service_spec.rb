require 'rails_helper'

describe CaseDeletionService do

  describe '#call' do
    let(:team)          { find_or_create :team_dacu }
    let(:user)          { team.users.first }
    let(:kase)          { create :accepted_case }
    let(:state_machine) { double ConfigurableStateMachine::Machine, destroy_case!: true }

    before(:each) do
      @service = CaseDeletionService.new(user, kase, reason_for_deletion: 'Because')
      allow(kase).to receive(:state_machine).and_return(state_machine)
    end

    context 'soft deleting a case' do

      it 'changes the attributes on the case' do
        @service.call
        expect(kase.deleted?).to eq true
      end

      it 'transitions the cases state' do
        expect(state_machine).to receive(:destroy_case!).with(acting_user: user, acting_team: team)
        @service.call
      end

      it 'sets results to :ok' do
        expect(@service.call).to eq :ok
      end

    end

    context 'if anything fails in the transaction' do
      it 'raises an error when it saves' do
        expect(kase).to receive(:update).and_return(false)
        expect(@service.call).to eq :error
      end
    end
  end
end
