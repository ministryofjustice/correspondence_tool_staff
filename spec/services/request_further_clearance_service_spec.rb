require 'rails_helper'

describe RequestFurtherClearanceService do
  let(:manager)           { create :manager }
  let(:accepted_case)     { create :accepted_case }

  describe '#call' do
    let(:thu_may_18) { Time.utc(2017, 5, 18, 12, 0, 0) }
    let(:tue_may_23) { Time.utc(2017, 5, 23, 12, 0, 0) }


    before(:each) do
      @service = RequestFurtherClearanceService.new(user: manager,
                                                    kase: accepted_case)
    end

    it 'flags a case for disclosure' do
      existing_approver_assignments = accepted_case.approver_assignments.count
      expect(existing_approver_assignments).to eq 0
      @service.call
      expect(accepted_case.approver_assignments.count).to eq 1
    end

    it 'sets the escalation date' do
      Timecop.freeze thu_may_18 do
        @service.call
        expect(accepted_case.escalation_deadline)
            .to eq tue_may_23.to_date
      end
    end

    it 'creates a transition' do
      expect { @service.call }
          .to change{ accepted_case
                          .transitions
                          .further_clearance.count }.by(1)
      tr = accepted_case.transitions[-2]
      expect(tr.event).to eq 'request_further_clearance'
      expect(tr.to_state).to eq 'drafting'
      expect(tr.acting_user_id).to eq manager.id
      expect(tr.acting_team_id).to eq manager.managing_teams.last.id
    end

    it 'returns ok' do
      @service.call
      expect(@service.result).to eq :ok
    end

    context 'when an error occurs' do
      it 'rolls-back changes' do
        old_deadline = accepted_case.escalation_deadline
        allow(accepted_case).to receive(:update!).and_throw(RuntimeError)
        @service.call

        #no case history
        request_clearance_transitions = accepted_case
                                            .transitions
                                            .where( event: 'request_further_clearance')
        expect(request_clearance_transitions.any?).to be false

        #not flagged
        flagged_assignments = accepted_case.approver_assignments
        expect(flagged_assignments.any?).to be false

        #deadline not changed
        expect(accepted_case.escalation_deadline).to eq old_deadline
      end

      it 'sets result to :error and returns same' do
        allow(accepted_case).to receive(:update!).and_throw(RuntimeError)
        result = @service.call
        expect(result).to eq :error
        expect(@service.result).to eq :error
      end
    end
  end
end
