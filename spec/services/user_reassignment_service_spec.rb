require 'rails_helper'

describe UserReassignmentService do
  let(:accepted_case)    { create(:accepted_case, responder: responder)}
  let(:responder)        { create :responder }
  let(:coworker)         { create :responder,
                                  responding_teams: [responding_team] }
  let(:responding_team ) { responder.responding_teams.first }
  let(:assignment)       { accepted_case
                             .assignments
                             .for_team(responding_team.id)
                             .last }

  describe '#initialize' do
    it 'uses the provided target_team by default' do
      urs = UserReassignmentService.new(target_user: coworker,
                                        acting_user: responder,
                                        assignment: assignment,
                                        target_team: :a_target_team)
      expect(urs.instance_variable_get(:@target_team)).to eq :a_target_team
    end

    it 'uses the provided acting_team by default' do
      urs = UserReassignmentService.new(target_user: coworker,
                                        acting_user: responder,
                                        assignment: assignment,
                                        acting_team: :an_acting_team)
      expect(urs.instance_variable_get(:@acting_team)).to eq :an_acting_team
    end

    context 'no target_team or acting_team provided' do
      let(:urs) { UserReassignmentService.new(target_user: coworker,
                                              acting_user: responder,
                                              assignment: assignment ) }

      it 'sets the target_team if not provided' do
        expect(urs.instance_variable_get(:@target_team)).to eq responding_team
      end

      it 'sets the acting_team if not provided' do
        expect(urs.instance_variable_get(:@target_team)).to eq responding_team
      end
    end
  end

  describe '#call' do
    let(:service) {
      UserReassignmentService.new(target_user: coworker,
                                  acting_user: responder,
                                  assignment: assignment )
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
