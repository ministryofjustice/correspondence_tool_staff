require 'rails_helper'

describe UserReassignmentService do


  describe '#call' do

    let(:accepted_case) { create(:accepted_case, responder: responder)}
    let(:responder)      { create :responder }
    let(:coworker)       { create :responder, responding_teams: [responding_team] }
    let(:responding_team ){ responder.responding_teams.first }
    let(:assignment)      { accepted_case.assignments.for_team(responding_team.id).last }
    let(:service) {
      UserReassignmentService.new( target_user: coworker,
                                   acting_user: responder,
                                   kase: accepted_case,
                                   target_assignment: assignment )
    }

    let(:policy)          { service.instance_variable_get(:@policy) }


    context 'Reassign the assignment' do
      it 'returns :ok' do
        expect(service.call).to eq :ok
      end

      it 'creates a transition record' do
        expect {
          service.call
        }.to change{ accepted_case.transitions.count }.by(1)

      end

      it 'updates the assignment record' do
        assignment = accepted_case.assignments
        service.call
        expect(accepted_case.assignments).to eq assignment
      end

    end

  end
end
