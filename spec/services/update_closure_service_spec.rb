require 'rails_helper'

describe UpdateClosureService do

  describe '#call' do
    let(:date_received)         { Date.new(2018, 10, 1) }
    let(:new_date_responded)    { Date.new(2018, 10, 5) }
    let(:frozen_date)           { Date.new(2018, 10, 10) }
    let(:team)                  { find_or_create :team_dacu }
    let(:user)                  { team.users.first }
    let(:kase)                  { create :closed_case, received_date: date_received }
    let(:state_machine)         { double ConfigurableStateMachine::Machine, update_closure!: true }

    before(:each) do
      @service = UpdateClosureService.new(kase, user, params)
      allow(kase).to receive(:state_machine).and_return(state_machine)
    end

    context 'when we have different params (i.e user edited data)' do
      let(:params) do
        {
            date_responded_dd: new_date_responded.day.to_s,
            date_responded_mm: new_date_responded.month.to_s,
            date_responded_yyyy: new_date_responded.year.to_s
        }
      end

      it 'changes the attributes on the case' do
        Timecop.freeze(frozen_date) do
          @service.call
          expect(kase.date_responded).to eq new_date_responded
        end
      end

      it 'transitions the cases state' do
        Timecop.freeze(frozen_date) do
          expect(state_machine).to receive(:update_closure!).with(acting_user: user, acting_team: team)
          @service.call
        end
      end

      it 'sets results to :ok' do
        Timecop.freeze(frozen_date) do
          @service.call
          expect(@service.result).to eq :ok
        end
      end
    end
  end
end
