require 'rails_helper'

describe NotifyResponderService, type: :service do
  let(:responded_case) { create :responded_case }
  let(:service)        { NotifyResponderService.new(kase: responded_case) }

  before do
    allow(ActionNotificationsMailer).to receive_message_chain(:notify_information_officers,
                                               :deliver_later)
  end
  context 'when it works' do

    it 'sets the result to ok' do

      service.call
      expect(service.result).to eq :ok
    end

    it 'emails' do
      service.call
      expect(ActionNotificationsMailer).to have_received(:notify_information_officers)
                                    .with notify_information_officers, responded_case
    end
  end
end

# describe CaseAssignResponderService, type: :service do
#   let(:manager)           { create :manager }
#   let(:unassigned_case)   { create :case }
#   let(:responding_team)   { create :responding_team }
#   let(:responder)         { responding_team.responders.first }
#   let(:service)           { CaseAssignResponderService
#                               .new team: responding_team,
#                                    kase: unassigned_case,
#                                    role: 'responding',
#                                    user: manager }
#   let(:new_assignment) { instance_double Assignment }
#
#
#
#   describe '#call' do
#     before do
#       allow(unassigned_case).to receive_message_chain(:assignments,
#                                                       new: new_assignment)
#       allow(unassigned_case.state_machine).to receive(:assign_responder!)
#       allow(ActionNotificationsMailer).to receive_message_chain(:new_assignment,
#                                                        :deliver_later)
#     end
#
#     context 'assignment is valid' do
#       before do
#         allow(new_assignment).to receive_messages valid?: true,
#                                                   save: true
#       end
#
#       it 'returns true on success' do
#         expect(service.call).to eq true
#       end
#
#       it 'sets the result to :ok' do
#         service.call
#         expect(service.result).to eq :ok
#       end
#
#       it 'triggers an assign_responder! event' do
#         service.call
#         expect(unassigned_case.state_machine)
#           .to have_received(:assign_responder!)
#                 .with manager,
#                       manager.managing_teams.first,
#                       responding_team
#       end
#
#       it 'saves the assignment' do
#         service.call
#         expect(service.assignment).to eq new_assignment
#       end
#
#       it 'emails the team' do
#         service.call
#         expect(ActionNotificationsMailer).to have_received(:new_assignment)
#                                       .with new_assignment,
#                                             responding_team.email
#       end
#
#       context 'a team with no email address' do
#         let(:other_responder) { create :responder }
#
#         before do
#           responding_team.responders << other_responder
#           responding_team.update email: nil
#         end
#
#         it 'emails each of the responders on the team' do
#           service.call
#           expect(ActionNotificationsMailer).to have_received(:new_assignment)
#                                         .with new_assignment,
#                                               responder.email
#           expect(ActionNotificationsMailer).to have_received(:new_assignment)
#                                         .with new_assignment,
#                                               other_responder.email
#         end
#       end
#     end
#
#     context 'created assignment is invalid' do
#       before do
#         allow(new_assignment).to receive_messages valid?: false,
#                                                   save: false
#       end
#
#       it 'sets the result' do
#         service.call
#         expect(service.result).to eq :could_not_create_assignment
#       end
#
#       it 'returns false' do
#         expect(service.call).to eq false
#       end
#     end
#   end
# end
