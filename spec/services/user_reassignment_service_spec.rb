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

      before do
        allow(ActionNotificationsMailer).to receive_message_chain(
                                            :case_assigned_to_another_user,
                                            :deliver_later)
      end

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

      it 'sends an email (only if different and user not assigning themselves' do
        service.call
        expect(ActionNotificationsMailer).to have_received(:case_assigned_to_another_user)
      end

      context 'when an error occurs' do
        it 'rolls-back changes' do
          old_user_id = assignment.user_id
          allow(assignment).to receive(:update).and_throw(RuntimeError)
          service.call

          # does not change the original assigned user
          expect(assignment.user_id).to eq old_user_id

          #no case history
          reassigned_user_transitions = accepted_case
                                              .transitions
                                              .where( event: 'reassign_user')
          expect(reassigned_user_transitions.any?).to be false
        end

        it 'sets result to :error and returns same' do
          allow(assignment).to receive(:update).and_throw(RuntimeError)
          result = service.call
          expect(result).to eq :error
          expect(service.result).to eq :error
        end

        it 'does not send an email' do
          allow(assignment).to receive(:update).and_throw(RuntimeError)
          service.call
          expect(ActionNotificationsMailer).to_not have_received(:case_assigned_to_another_user)
        end
      end
    end

    context 'user assigns a case to themselves' do
      let(:service) {
        UserReassignmentService.new(target_user: responder,
                                    acting_user: responder,
                                    assignment: assignment )
      }

      before do
        allow(ActionNotificationsMailer).to receive_message_chain(
                                            :case_assigned_to_another_user,
                                            :deliver_later)
      end

      it 'should not send email' do
        service.call
        expect(service.result).to eq :ok
        expect(ActionNotificationsMailer).to_not have_received(:case_assigned_to_another_user)
      end
    end

    context 'unassigned case' do
      let(:approver)         { create(:disclosure_specialist) }
      let(:unassigned_case)  { create(:foi_case, :flagged_accepted, approver: approver) }
      let(:approver_coworker){ create(:disclosure_specialist) }
      let(:disclosure_team)  { approver.approving_team }
      let(:assignment)       { unassigned_case
                                 .assignments
                                 .for_team(disclosure_team.id)
                                 .last }

      let(:service) {
        UserReassignmentService.new(target_user: approver_coworker,
                                    acting_user: approver,
                                    assignment: assignment )
      }

      let(:policy)          { service.instance_variable_get(:@policy) }

      context 'Reassign the assignment' do

        before do
          allow(ActionNotificationsMailer).to receive_message_chain(
                                              :case_assigned_to_another_user,
                                              :deliver_later)
        end

        it 'returns :ok' do
          expect(service.call).to eq :ok
        end

        it 'creates a transition record' do
          expect {
            service.call
          }.to change{ unassigned_case.transitions.count }.by(1)

        end

        it 'updates the assignment record' do
          assignment = unassigned_case.assignments
          service.call
          expect(unassigned_case.assignments).to eq assignment
        end

        it 'sends an email (only if different and user not assigning themselves' do
          service.call
          expect(ActionNotificationsMailer).to have_received(:case_assigned_to_another_user)
        end
      end
    end
  end
end
