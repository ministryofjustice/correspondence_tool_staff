require 'rails_helper'

describe Case::FOI::StandardStateMachine do
  context 'standard workflow' do

##################### MANAGER  ############################

    context 'manager' do

      let(:manager)   { create :manager}

      context 'unassigned state' do
        it 'should show permitted events' do
          k = create :case

          expect(k.current_state).to eq 'unassigned'
          expect(k.state_machine.permitted_events(manager)).to eq [:add_message_to_case,
                                                                   :assign_responder,
                                                                   :destroy_case,
                                                                   :edit_case,
                                                                   :flag_for_clearance,
                                                                   :link_a_case,
                                                                   :remove_linked_case,
                                                                   :request_further_clearance]
        end
      end


      context 'awaiting responder state' do
        it 'shows events' do
          k = create :awaiting_responder_case

          expect(k.current_state).to eq 'awaiting_responder'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :assign_to_new_team,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :flag_for_clearance,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :request_further_clearance]
        end
      end

      context 'drafting state' do
        it 'shows events' do
          k = create :accepted_case

          expect(k.current_state).to eq 'drafting'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :assign_to_new_team,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :flag_for_clearance,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :request_further_clearance]
        end
      end

      context 'awaiting_dispatch' do
        it 'shows events' do
          k = create :case_with_response

          expect(k.current_state).to eq 'awaiting_dispatch'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :flag_for_clearance,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :request_further_clearance]
        end
      end

      context 'responded' do
        it 'shows events' do
          k = create :responded_case

          expect(k.current_state).to eq 'responded'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :close,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :link_a_case,
                                                                      :remove_linked_case]
        end
      end

      context 'closed' do
        it 'shows events' do
          k = create :closed_case

          expect(k.current_state).to eq 'closed'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:destroy_case,
                                                                      :edit_case,
                                                                      :link_a_case,
                                                                      :remove_linked_case]
        end
      end
    end


##################### RESPONDER ############################

    context 'responder' do

      context 'responder not in team' do

        let(:responder)   { create :responder }

        context 'unassigned state' do
          it 'should show permitted events' do
            k = create :case

            expect(k.current_state).to eq 'unassigned'
            expect(k.state_machine.permitted_events(responder.id)).to be_empty
          end
        end

        context 'awaiting responder state' do
          it 'shows events' do
            k = create :awaiting_responder_case

            expect(k.current_state).to eq 'awaiting_responder'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case, :remove_linked_case]
          end
        end

        context 'drafting state' do
          it 'shows events' do
            k = create :accepted_case

            expect(k.current_state).to eq 'drafting'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case, :remove_linked_case]
          end
        end

        context 'awaiting_dispatch' do
          it 'shows events' do
            k = create :case_with_response

            expect(k.current_state).to eq 'awaiting_dispatch'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case,
                                                                          :remove_linked_case]
          end
        end

        context 'responded state' do
          it 'shows events' do
            k = create :responded_case

            expect(k.current_state).to eq 'responded'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case, :remove_linked_case]
          end
        end
        context 'closed state' do
          it 'shows events' do
            k = create :closed_case

            expect(k.current_state).to eq 'closed'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case, :remove_linked_case]
          end
        end
      end

      context 'responder in assigned team' do
        # Request further clearance is not permitted by the policies so has been removed
        # from state machine permitted events check
        context 'awaiting_responder state' do
          it 'shows events' do
            k = create :awaiting_responder_case
            responder = responder_in_assigned_team(k)
            permitted_events = k.state_machine.permitted_events(responder.id) - [:request_further_clearance]

            expect(k.current_state).to eq 'awaiting_responder'
            expect(permitted_events).to eq [:accept_responder_assignment,
                                            :add_message_to_case,
                                            :link_a_case,
                                            :reject_responder_assignment,
                                            :remove_linked_case]

          end
        end

        context 'drafting state' do
          it 'shows events' do
            k = create :accepted_case
            responder = responder_in_assigned_team(k)

            expect(k.current_state).to eq 'drafting'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                          :add_responses,
                                                                          :link_a_case,
                                                                          :reassign_user,
                                                                          :remove_linked_case,
                                                                          ]
          end
        end

        context 'awaiting_dispatch state' do
          it 'shows events' do
            k = create :case_with_response
            responder = responder_in_assigned_team(k)

            expect(k.current_state).to eq 'awaiting_dispatch'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                          :add_responses,
                                                                          :link_a_case,
                                                                          :reassign_user,
                                                                          :remove_linked_case,
                                                                          :remove_response,
                                                                          :respond]
          end
        end

        context 'responded state' do
          it 'shows events' do
            k = create :responded_case
            responder = responder_in_assigned_team(k)

            expect(k.current_state).to eq 'responded'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                          :link_a_case,
                                                                          :remove_linked_case]
          end
        end

        context 'closed state' do
          it 'shows events' do
            k = create :closed_case
            responder = responder_in_assigned_team(k)

            expect(k.current_state).to eq 'closed'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case, :remove_linked_case]
          end
        end
      end

      def responder_in_assigned_team(k)
        create :responder, responding_teams: [k.responding_team]
      end
    end


##################### APPROVER ############################


    context 'approver' do
      context 'unassigned approver' do
        let(:approver)   { create :disclosure_specialist}

        context 'unassigned state' do
          it 'should show permitted events' do
            k = create :case

            expect(k.current_state).to eq 'unassigned'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:flag_for_clearance,
                                                                         :link_a_case,
                                                                         :remove_linked_case,
                                                                         :take_on_for_approval]

          end
        end

        context 'awaiting responder state' do
          it 'shows events' do
            k = create :awaiting_responder_case

            expect(k.current_state).to eq 'awaiting_responder'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:flag_for_clearance,
                                                                         :link_a_case,
                                                                         :remove_linked_case,
                                                                         :take_on_for_approval]
          end
        end

        context 'drafting state' do
          it 'shows events' do
            k = create :accepted_case

            expect(k.current_state).to eq 'drafting'
            expect(k.state_machine.permitted_events(approver.id)).to eq [ :link_a_case,
                                                                          :remove_linked_case,
                                                                          :take_on_for_approval]
          end
        end

        context 'awaiting_dispatch' do
          it 'shows events' do
            k = create :case_with_response

            expect(k.current_state).to eq 'awaiting_dispatch'
            expect(k.state_machine.permitted_events(approver.id)).to eq [ :link_a_case,
                                                                          :remove_linked_case,
                                                                          :take_on_for_approval]
          end
        end

        context 'responded' do
          it 'shows events' do
            k = create :responded_case

            expect(k.current_state).to eq 'responded'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:link_a_case,
                                                                         :remove_linked_case]
          end
        end

        context 'closed' do
          it 'shows events' do
            k = create :closed_case

            expect(k.current_state).to eq 'closed'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:link_a_case, :remove_linked_case]
          end
        end
      end
    end
  end
end
