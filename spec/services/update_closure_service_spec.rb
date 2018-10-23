require 'rails_helper'

describe UpdateClosureService do

  describe '#call' do
    let(:team)          { find_or_create :team_dacu }
    let(:user)          { team.users.first }
    let(:kase)          { create :closed_case }
    let(:state_machine) { double ConfigurableStateMachine::Machine, update_closure!: true }

    before(:each) do
      @service = UpdateClosureService.new(kase, user, params)
      allow(kase).to receive(:state_machine).and_return(state_machine)
    end

    context 'when we have different params (i.e user edited data)' do
      let(:new_date)      { Date.new(2018, 10, 5) }
      let(:params)        { { date_responded_dd: '5',
                              date_responded_mm: '10',
                              date_responded_yyyy: '2018'   }}

      it 'changes the attributes on the case' do
        Timecop.freeze(Time.new(2018, 10, 10)) do
          @service.call
          expect(kase.date_responded).to eq new_date
        end
      end

      it 'transitions the cases state' do
        Timecop.freeze(Time.new(2018, 10, 10)) do
          expect(state_machine).to receive(:update_closure!).with(acting_user: user, acting_team: team)
          @service.call
        end
      end

      it 'sets results to :ok' do
        Timecop.freeze(Time.new(2018, 10, 10)) do
          @service.call
          expect(@service.result).to eq :ok
        end
      end
    end
  end
end
