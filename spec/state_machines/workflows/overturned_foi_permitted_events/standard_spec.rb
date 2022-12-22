require 'rails_helper'

describe ConfigurableStateMachine::Machine do
  context 'standard workflow' do

##################### MANAGER  ############################

    context 'manager' do

      let(:manager)   { find_or_create :disclosure_bmt_user}

      context 'unassigned state' do
        it 'should show permitted events' do
          k = create :overturned_ico_foi
          expect(k.class).to eq Case::OverturnedICO::FOI
          expect(k.workflow).to eq 'standard'
          expect(k.current_state).to eq 'unassigned'
          expect(k.state_machine.permitted_events(manager)).to eq [:add_message_to_case,
                                                                   :assign_responder,
                                                                   :destroy_case,
                                                                   :flag_for_clearance,
                                                                   :link_a_case,
                                                                   :remove_linked_case,
                                                                   :request_further_clearance]
        end
      end


      context 'awaiting responder state' do
        it 'shows events' do
          k = create :awaiting_responder_ot_ico_foi
          expect(k.class).to eq Case::OverturnedICO::FOI
          expect(k.workflow).to eq 'standard'
          expect(k.current_state).to eq 'awaiting_responder'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :assign_to_new_team,
                                                                      :destroy_case,
                                                                      :flag_for_clearance,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :request_further_clearance]
        end
      end

      context 'drafting state' do
        it 'shows events' do
          k = create :accepted_ot_ico_foi
          expect(k.class).to eq Case::OverturnedICO::FOI
          expect(k.workflow).to eq 'standard'
          expect(k.current_state).to eq 'drafting'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :assign_to_new_team,
                                                                      :destroy_case,
                                                                      :extend_for_pit,
                                                                      :flag_for_clearance,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :request_further_clearance,
                                                                      :unassign_from_user]
        end
      end

      context 'awaiting_dispatch' do
        it 'shows events' do
          k = create :with_response_ot_ico_foi
          expect(k.class).to eq Case::OverturnedICO::FOI
          expect(k.workflow).to eq 'standard'
          expect(k.current_state).to eq 'awaiting_dispatch'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :destroy_case,
                                                                      :extend_for_pit,
                                                                      :flag_for_clearance,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :request_further_clearance,
                                                                      :unassign_from_user]
        end
      end

      context 'responded' do
        it 'shows events' do
          k = create :responded_ot_ico_foi
          expect(k.class).to eq Case::OverturnedICO::FOI
          expect(k.workflow).to eq 'standard'
          expect(k.current_state).to eq 'responded'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :close,
                                                                      :destroy_case,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :send_back,
                                                                      :unassign_from_user]
        end
      end

      context 'closed' do
        it 'shows events' do
          k = create :closed_ot_ico_foi
          expect(k.class).to eq Case::OverturnedICO::FOI
          expect(k.workflow).to eq 'standard'
          expect(k.current_state).to eq 'closed'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :assign_to_new_team,
                                                                      :destroy_case,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :update_closure]
        end
      end
    end


##################### RESPONDER ############################

    context 'responder' do

      context 'responder not in team' do

        let(:responder)   { create :responder }

        context 'unassigned state' do
          it 'should show permitted events' do
            k = create :overturned_ico_foi
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'standard'
            expect(k.current_state).to eq 'unassigned'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case, :remove_linked_case]
          end
        end

        context 'awaiting responder state' do
          it 'shows events' do
            k = create :awaiting_responder_ot_ico_foi
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'standard'
            expect(k.current_state).to eq 'awaiting_responder'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case, :remove_linked_case]
          end
        end

        context 'drafting state' do
          it 'shows events' do
            k = create :accepted_ot_ico_foi
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'standard'
            expect(k.current_state).to eq 'drafting'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case, :remove_linked_case]
          end
        end

        context 'awaiting_dispatch' do
          it 'shows events' do
            k = create :with_response_ot_ico_foi
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'standard'
            expect(k.current_state).to eq 'awaiting_dispatch'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case,
                                                                          :remove_linked_case]
          end
        end

        context 'responded state' do
          it 'shows events' do
            k = create :responded_ot_ico_foi
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'standard'
            expect(k.current_state).to eq 'responded'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case, :remove_linked_case]
          end
        end
        context 'closed state' do
          it 'shows events' do
            k = create :closed_ot_ico_foi
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'standard'
            expect(k.current_state).to eq 'closed'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                          :link_a_case,
                                                                          :remove_linked_case]
          end
        end
      end

      context 'responder in assigned team' do
        # Request further clearance is not permitted by the policies so has been removed
        # from state machine permitted events check
        context 'awaiting_responder state' do
          it 'shows events' do
            k = create :awaiting_responder_ot_ico_foi
            expect(k.class).to eq Case::OverturnedICO::FOI
            responder = responder_in_assigned_team(k)
            permitted_events = k.state_machine.permitted_events(responder.id) - [:request_further_clearance]
            expect(k.workflow).to eq 'standard'
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
            k = create :accepted_ot_ico_foi
            expect(k.class).to eq Case::OverturnedICO::FOI
            responder = responder_in_assigned_team(k)
            expect(k.workflow).to eq 'standard'
            expect(k.current_state).to eq 'drafting'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                          :add_responses,
                                                                          :link_a_case,
                                                                          :reassign_user,
                                                                          :remove_linked_case,
                                                                          :remove_response
                                                                         ]
          end
        end

        context 'awaiting_dispatch state' do
          it 'shows events' do
            k = create :with_response_ot_ico_foi
            expect(k.class).to eq Case::OverturnedICO::FOI
            responder = responder_in_assigned_team(k)
            expect(k.workflow).to eq 'standard'
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
            k = create :responded_ot_ico_foi
            expect(k.class).to eq Case::OverturnedICO::FOI
            responder = responder_in_assigned_team(k)
            expect(k.workflow).to eq 'standard'
            expect(k.current_state).to eq 'responded'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                          :link_a_case,
                                                                          :remove_linked_case]
          end
        end

        context 'closed state' do
          it 'shows events' do
            k = create :closed_ot_ico_foi
            expect(k.class).to eq Case::OverturnedICO::FOI
            responder = responder_in_assigned_team(k)
            expect(k.workflow).to eq 'standard'
            expect(k.current_state).to eq 'closed'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                          :link_a_case,
                                                                          :remove_linked_case]
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
        let(:approver)   { find_or_create :disclosure_specialist}

        context 'unassigned state' do
          it 'should show permitted events' do
            k = create :overturned_ico_foi
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'standard'
            expect(k.current_state).to eq 'unassigned'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:flag_for_clearance,
                                                                         :link_a_case,
                                                                         :remove_linked_case,
                                                                         :take_on_for_approval]

          end
        end

        context 'awaiting responder state' do
          it 'shows events' do
            k = create :awaiting_responder_ot_ico_foi
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'standard'
            expect(k.current_state).to eq 'awaiting_responder'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:flag_for_clearance,
                                                                         :link_a_case,
                                                                         :remove_linked_case,
                                                                         :take_on_for_approval]
          end
        end

        context 'drafting state' do
          it 'shows events' do
            k = create :accepted_ot_ico_foi
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'standard'
            expect(k.current_state).to eq 'drafting'
            expect(k.state_machine.permitted_events(approver.id)).to eq [ :flag_for_clearance,
                                                                          :link_a_case,
                                                                          :remove_linked_case,
                                                                          :take_on_for_approval]
          end
        end

        context 'awaiting_dispatch' do
          it 'shows events' do
            k = create :with_response_ot_ico_foi
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'standard'
            expect(k.current_state).to eq 'awaiting_dispatch'
            expect(k.state_machine.permitted_events(approver.id)).to eq [ :link_a_case,
                                                                          :remove_linked_case,
                                                                          :take_on_for_approval]
          end
        end

        context 'responded' do
          it 'shows events' do
            k = create :responded_ot_ico_foi
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'standard'
            expect(k.current_state).to eq 'responded'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:link_a_case,
                                                                         :remove_linked_case]
          end
        end

        context 'closed' do
          it 'shows events' do
            k = create :closed_ot_ico_foi
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'standard'
            expect(k.current_state).to eq 'closed'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:add_message_to_case,
                                                                         :link_a_case,
                                                                         :remove_linked_case]
          end
        end
      end
    end
  end
end
