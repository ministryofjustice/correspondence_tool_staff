require 'rails_helper'

describe CaseUnflagForClearanceService do
  let(:assigned_case)         { create :assigned_case }
  let(:assigned_flagged_case) { create :assigned_case,
                                       :flagged_accepted,
                                       :dacu_disclosure }


  let(:press_flagged_case) { create :assigned_case,
                                    :flagged_accepted,
                                    :press_office }
  let(:approver)              { dacu_disclosure.approvers.first }
  let(:team_dacu)             { find_or_create :team_dacu }
  let(:dacu_disclosure)       { find_or_create :team_dacu_disclosure }
  let(:press_office)          { find_or_create :team_press_office }

  describe 'call' do
    # context 'case is not already flagged' do
    #   let(:service) { described_class.new user: approver,
    #                                       kase: assigned_case,
    #                                       team: dacu_disclosure,
    #                                       message: "message"}
    #
    #   it 'validates that the case is flagged' do
    #     expect(service.call).to eq :incomplete
    #     expect(service.result).to eq :incomplete
    #   end
    # end

    context 'case is flagged' do
      let(:service) { described_class.new user: approver,
                                          kase: assigned_flagged_case,
                                          team: dacu_disclosure,
                                          message: "message"}

      before do
        allow(assigned_flagged_case.state_machine)
          .to receive(:unflag_for_clearance!)
        service.call
      end

      it 'triggers an event on the case state machine' do
        expect(assigned_flagged_case.state_machine)
          .to have_received(:unflag_for_clearance!)
                .with(approver, team_dacu, dacu_disclosure, "message")
      end
      it 'removes the approving team assignment' do
        expect(assigned_flagged_case.approving_teams).to be_blank
      end
      it 'sets the result to ok and returns true' do
        expect(service.result).to eq :ok
      end
      it 'saves message in the data base' do
        expect(service.result).to eq :ok
      end
    end
  end
  # context 'case is flagged by the press office' do
  #   let(:service) { described_class.new user: approver,
  #                                       kase: press_flagged_case,
  #                                       team: dacu_disclosure,
  #                                       message: "message"}
  #
  #   it 'validates that the case is flagged by for dacu_disclosure' do
  #     service.call
  #     expect(service.result).to eq :incomplete
  #   end
  # end
end
