require 'rails_helper'

describe ConfigurableStateMachine::Machine do
  context 'full_approval workflow' do

    ##################### MANAGER FLAGGED ############################

    context 'manager' do

      let(:manager)   { create :manager}

      context 'unassigned state' do
        it 'should show permitted events' do
          k = create :overturned_ico_foi, :flagged, :press_office
          expect(k.class).to eq Case::OverturnedICO::FOI
          expect(k.workflow).to eq 'full_approval'
          expect(k.current_state).to eq 'unassigned'
          expect(k.state_machine.permitted_events(manager)).to eq [ :add_message_to_case,
                                                                    :assign_responder,
                                                                    :destroy_case,
                                                                    :edit_case,
                                                                    :flag_for_clearance,
                                                                    :link_a_case,
                                                                    :remove_linked_case]
        end
      end


      context 'awaiting responder state' do
        it 'shows events' do
          k = create :awaiting_responder_ot_ico_foi, :flagged, :press_office
          expect(k.class).to eq Case::OverturnedICO::FOI
          expect(k.workflow).to eq 'full_approval'
          expect(k.current_state).to eq 'awaiting_responder'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :assign_to_new_team,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :flag_for_clearance,
                                                                      :link_a_case,
                                                                      :remove_linked_case]
        end
      end

      context 'drafting state' do
        it 'shows events' do
          k = create :accepted_ot_ico_foi, :flagged, :press_office
          expect(k.class).to eq Case::OverturnedICO::FOI
          expect(k.workflow).to eq 'full_approval'
          expect(k.current_state).to eq 'drafting'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :assign_to_new_team,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :extend_for_pit,
                                                                      :flag_for_clearance,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :unassign_from_user]
        end
      end

      context 'pending_dacu_clearance' do
        it 'shows events' do
          k = create :pending_dacu_clearance_ot_ico_foi, :flagged, :press_office
          expect(k.class).to eq Case::OverturnedICO::FOI
          expect(k.workflow).to eq 'full_approval'
          expect(k.current_state).to eq 'pending_dacu_clearance'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :extend_for_pit,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :unassign_from_user]
        end
      end

      context 'pending_press_clearance' do
        it 'shows events' do
          k = create :pending_press_clearance_ot_ico_foi, :flagged, :press_office
          expect(k.class).to eq Case::OverturnedICO::FOI
          expect(k.workflow).to eq 'full_approval'
          expect(k.current_state).to eq 'pending_press_office_clearance'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :extend_for_pit,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :unassign_from_user]
        end
      end

      context 'pending_private_clearance' do
        it 'shows events' do
          k = create :pending_private_clearance_ot_ico_foi
          expect(k.class).to eq Case::OverturnedICO::FOI
          expect(k.workflow).to eq 'full_approval'
          expect(k.current_state).to eq 'pending_private_office_clearance'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :extend_for_pit,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :unassign_from_user]
        end
      end

      context 'awaiting_dispatch' do
        it 'shows events' do
          k = create :with_response_ot_ico_foi, :flagged, :press_office
          expect(k.class).to eq Case::OverturnedICO::FOI
          expect(k.workflow).to eq 'full_approval'
          expect(k.current_state).to eq 'awaiting_dispatch'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :extend_for_pit,
                                                                      :flag_for_clearance,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :unassign_from_user]
        end
      end

      context 'responded' do
        it 'shows events' do
          k = create :responded_full_approval_ot_ico_foi, :flagged, :press_office
          expect(k.class).to eq Case::OverturnedICO::FOI
          expect(k.workflow).to eq 'full_approval'
          expect(k.current_state).to eq 'responded'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :close,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :unassign_from_user ]
        end
      end

      context 'closed' do
        it 'shows events' do
          k = create :closed_full_approval_ot_ico_foi, :flagged, :press_office
          expect(k.class).to eq Case::OverturnedICO::FOI
          expect(k.workflow).to eq 'full_approval'
          expect(k.current_state).to eq 'closed'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :assign_to_new_team,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :update_closure]
        end
      end
    end


    ##################### RESPONDER FLAGGED ############################

    context 'responder' do
      context 'responder not in team' do

        let(:responder)   { create :responder }

        context 'unassigned state' do
          it 'should show permitted events' do
            k = create :overturned_ico_foi, :flagged, :press_office
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'full_approval'
            expect(k.current_state).to eq 'unassigned'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case, :remove_linked_case]
          end
        end

        context 'awaiting responder state' do
          it 'shows events' do
            k = create :awaiting_responder_ot_ico_foi, :flagged, :press_office
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'full_approval'
            expect(k.current_state).to eq 'awaiting_responder'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case,:remove_linked_case]
          end
        end

        context 'drafting state' do
          it 'shows events' do
            k = create :accepted_ot_ico_foi, :flagged, :press_office
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'full_approval'
            expect(k.current_state).to eq 'drafting'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case,
                                                                          :remove_linked_case,
                                                                          :upload_responses]
          end
        end

        context 'pending_dacu_clearance state' do
          it 'shows events' do
            k = create :pending_dacu_clearance_ot_ico_foi, :flagged, :press_office
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'full_approval'
            expect(k.current_state).to eq 'pending_dacu_clearance'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case,
                                                                          :remove_linked_case]
          end
        end

        context 'pending_press_clearance state' do
          it 'shows events' do
            k = create :pending_press_clearance_ot_ico_foi, :flagged, :press_office
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'full_approval'
            expect(k.current_state).to eq 'pending_press_office_clearance'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case, :remove_linked_case]
          end
        end

        context 'pending_private_clearance state' do
          it 'shows events' do
            k = create :pending_private_clearance_ot_ico_foi
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'full_approval'
            expect(k.current_state).to eq 'pending_private_office_clearance'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case, :remove_linked_case]
          end
        end

        context 'awaiting_dispatch' do
          it 'shows events' do
            k = create :with_response_ot_ico_foi, :flagged, :press_office
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'full_approval'
            expect(k.current_state).to eq 'awaiting_dispatch'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case,
                                                                          :remove_linked_case]
          end
        end

        context 'responded state' do
          it 'shows events' do
            k = create :responded_full_approval_ot_ico_foi, :flagged, :press_office
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'full_approval'
            expect(k.current_state).to eq 'responded'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case, :remove_linked_case]
          end
        end
      end

      context 'responder in assigned team' do
        context 'awaiting_responder state' do
          it 'shows events' do
            k = create :awaiting_responder_ot_ico_foi, :flagged, :press_office
            responder = responder_in_assigned_team(k)
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'full_approval'
            expect(k.current_state).to eq 'awaiting_responder'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:accept_responder_assignment,
                                                                          :add_message_to_case,
                                                                          :link_a_case,
                                                                          :reject_responder_assignment,
                                                                          :remove_linked_case]
          end
        end

        context 'drafting state' do
          it 'shows events' do
            k = create :accepted_ot_ico_foi, :flagged, :press_office
            responder = responder_in_assigned_team(k)
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'full_approval'
            expect(k.current_state).to eq 'drafting'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                          :add_responses,
                                                                          :link_a_case,
                                                                          :reassign_user,
                                                                          :remove_linked_case,
                                                                          :remove_response,
                                                                          :upload_responses]
          end
        end

        context 'pending_dacu_clearance state' do
          it 'shows events' do
            k = create :pending_dacu_clearance_ot_ico_foi, :flagged, :press_office
            responder = responder_in_assigned_team(k)
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'full_approval'
            expect(k.current_state).to eq 'pending_dacu_clearance'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                          :link_a_case,
                                                                          :reassign_user,
                                                                          :remove_linked_case]
          end
        end

        context 'pending_press_clearance state' do
          it 'shows events' do
            k = create :pending_press_clearance_ot_ico_foi
            responder = responder_in_assigned_team(k)
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'full_approval'
            expect(k.current_state).to eq 'pending_press_office_clearance'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                          :link_a_case,
                                                                          :reassign_user,
                                                                          :remove_linked_case]
          end
        end

        context 'pending_private_clearance state' do
          it 'shows events' do
            k = create :pending_private_clearance_ot_ico_foi
            responder = responder_in_assigned_team(k)
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'full_approval'
            expect(k.current_state).to eq 'pending_private_office_clearance'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                          :link_a_case,
                                                                          :reassign_user,
                                                                          :remove_linked_case]
          end
        end

        context 'awaiting_dispatch state' do
          it 'shows events' do
            k = create :with_response_ot_ico_foi, :flagged, :press_office
            responder = responder_in_assigned_team(k)
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'full_approval'
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
            k = create :responded_full_approval_ot_ico_foi, :flagged, :press_office
            responder = responder_in_assigned_team(k)
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'full_approval'
            expect(k.current_state).to eq 'responded'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case, :link_a_case, :remove_linked_case]
          end
        end

        context 'close state' do
          it 'shows events' do
            k = create :closed_full_approval_ot_ico_foi, :flagged, :press_office
            responder = responder_in_assigned_team(k)
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'full_approval'
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


    ##################### APPROVER FLAGGED ############################

    context 'approver' do
      let(:team_dacu_disclosure)  { find_or_create :team_dacu_disclosure }
      let(:disclosure_specialist) { find_or_create :disclosure_specialist }
      let(:approver)              { disclosure_specialist }

      context 'unassigned approver' do
        context 'unassigned state' do
          it 'should show permitted events' do
            k = create :overturned_ico_foi, :flagged, :press_office
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'full_approval'
            expect(k.current_state).to eq 'unassigned'
            expect(k.state_machine.permitted_events(disclosure_specialist.id))
              .to eq [:accept_approver_assignment,
                      :add_message_to_case,
                      :flag_for_clearance,
                      :link_a_case,
                      :remove_linked_case]
          end
        end

        context 'awaiting responder state' do
          it 'shows events' do
            k = create :awaiting_responder_ot_ico_foi, :flagged, :press_office
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'full_approval'
            expect(k.current_state).to eq 'awaiting_responder'
            expect(k.state_machine.permitted_events(approver.id))
              .to eq [:accept_approver_assignment,
                      :add_message_to_case,
                      :flag_for_clearance,
                      :link_a_case,
                      :reassign_user,
                      :remove_linked_case]
          end
        end

        context 'drafting state' do
          it 'shows events' do
            k = create :accepted_ot_ico_foi, :flagged, :press_office
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'full_approval'
            expect(k.current_state).to eq 'drafting'
            expect(k.state_machine.permitted_events(approver.id))
              .to eq [ :accept_approver_assignment,
                       :add_message_to_case,
                       :flag_for_clearance,
                       :link_a_case,
                       :reassign_user,
                       :remove_linked_case]
          end
        end

        context 'pending_dacu_clearance state' do
          it 'shows events' do
            k = create :pending_dacu_clearance_ot_ico_foi,
                       :press_office,
                       :flagged
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'full_approval'
            expect(k.current_state).to eq 'pending_dacu_clearance'
            expect(k.state_machine.permitted_events(approver.id))
              .to eq [:accept_approver_assignment,
                      :add_message_to_case,
                      :link_a_case,
                      :reassign_user,
                      :remove_linked_case]
          end
        end
      end

      context 'assigned approver' do
        context 'unassigned state' do

          it 'should show permitted events' do
            k = create :overturned_ico_foi, :flagged_accepted, :press_office
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'full_approval'
            expect(k.current_state).to eq 'unassigned'
            expect(k.state_machine.permitted_events(approver.id)).to eq [ :add_message_to_case,
                                                                          :flag_for_clearance,
                                                                          :link_a_case,
                                                                          :reassign_user,
                                                                          :remove_linked_case]
          end
        end

        context 'awaiting responder state' do
          it 'shows events' do
            k = create :awaiting_responder_ot_ico_foi, :flagged_accepted, :press_office
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'full_approval'
            expect(k.current_state).to eq 'awaiting_responder'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:add_message_to_case,
                                                                         :flag_for_clearance,
                                                                         :link_a_case,
                                                                         :reassign_user,
                                                                         :remove_linked_case]
          end
        end

        context 'drafting state' do
          it 'shows events' do
            k = create :accepted_ot_ico_foi, :flagged_accepted, :press_office
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'full_approval'
            expect(k.current_state).to eq 'drafting'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:add_message_to_case,
                                                                         :flag_for_clearance,
                                                                         :link_a_case,
                                                                         :reassign_user,
                                                                         :remove_linked_case]
          end
        end

        context 'pending_dacu_clearance state' do
          it 'shows events' do
            k = create :pending_dacu_clearance_ot_ico_foi, :flagged_accepted, :press_office
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'full_approval'
            expect(k.current_state).to eq 'pending_dacu_clearance'
            expect(k.state_machine.permitted_events(approver.id))
              .to match_array [
                    :add_message_to_case,
                    :approve,
                    :approve_and_bypass,
                    :link_a_case,
                    :reassign_user,
                    :remove_linked_case,
                    :upload_response_and_approve,
                    :upload_response_and_return_for_redraft,
                    :upload_response_approve_and_bypass,
                  ]
          end
        end

        context 'pending_press_clearance state' do
          it 'shows events' do
            k = create :pending_press_clearance_ot_ico_foi
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'full_approval'
            expect(k.current_state).to eq 'pending_press_office_clearance'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:add_message_to_case,
                                                                         :link_a_case,
                                                                         :reassign_user,
                                                                         :remove_linked_case]
          end
        end

        context 'pending_private_clearance state' do
          it 'shows events' do
            k = create :pending_private_clearance_ot_ico_foi
            expect(k.class).to eq Case::OverturnedICO::FOI
            expect(k.workflow).to eq 'full_approval'
            expect(k.current_state).to eq 'pending_private_office_clearance'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:add_message_to_case,
                                                                         :link_a_case,
                                                                         :reassign_user,
                                                                         :remove_linked_case]
          end
        end
      end
    end

    ##################### APPROVER FLAGGED ############################
    let(:press_officer) { find_or_create :press_officer }

    context 'assigned press officer' do
      context 'unassigned state' do

        it 'should show permitted events' do
          k = create :overturned_ico_foi, :flagged_accepted, :press_office
          expect(k.class).to eq Case::OverturnedICO::FOI
          expect(k.workflow).to eq 'full_approval'
          expect(k.current_state).to eq 'unassigned'
          expect(k.state_machine.permitted_events(press_officer.id))
            .to eq [ :add_message_to_case,
                     :flag_for_clearance,
                     :link_a_case,
                     :reassign_user,
                     :remove_linked_case,
                     :unflag_for_clearance]
        end
      end

      context 'awaiting responder state' do
        it 'shows events' do
          k = create :awaiting_responder_ot_ico_foi, :flagged_accepted, :press_office
          expect(k.class).to eq Case::OverturnedICO::FOI
          expect(k.workflow).to eq 'full_approval'
          expect(k.current_state).to eq 'awaiting_responder'
          expect(k.state_machine.permitted_events(press_officer.id))
            .to eq [:add_message_to_case,
                    :flag_for_clearance,
                    :link_a_case,
                    :reassign_user,
                    :remove_linked_case,
                    :unflag_for_clearance]
        end
      end

      context 'drafting state' do
        it 'shows events' do
          k = create :accepted_ot_ico_foi, :flagged_accepted, :press_office
          expect(k.class).to eq Case::OverturnedICO::FOI
          expect(k.workflow).to eq 'full_approval'
          expect(k.current_state).to eq 'drafting'
          expect(k.state_machine.permitted_events(press_officer.id))
            .to eq [:add_message_to_case,
                    :flag_for_clearance,
                    :link_a_case,
                    :reassign_user,
                    :remove_linked_case,
                    :unflag_for_clearance]
        end
      end

      context 'pending_dacu_clearance state' do
        it 'shows events' do
          k = create :pending_dacu_clearance_ot_ico_foi, :flagged_accepted, :press_office
          expect(k.class).to eq Case::OverturnedICO::FOI
          expect(k.workflow).to eq 'full_approval'
          expect(k.current_state).to eq 'pending_dacu_clearance'
          expect(k.state_machine.permitted_events(press_officer.id))
            .to match_array [:add_message_to_case,
                             :link_a_case,
                             :reassign_user,
                             :remove_linked_case,
                             :unflag_for_clearance]
        end
      end

      context 'pending_press_clearance state' do
        it 'shows events' do
          k = create :pending_press_clearance_ot_ico_foi
          expect(k.class).to eq Case::OverturnedICO::FOI
          expect(k.workflow).to eq 'full_approval'
          expect(k.current_state).to eq 'pending_press_office_clearance'
          expect(k.state_machine.permitted_events(press_officer.id))
            .to eq [:add_message_to_case,
                    :approve,
                    :execute_request_amends,
                    :link_a_case,
                    :reassign_user,
                    :remove_linked_case,
                    :request_amends,
                    :unflag_for_clearance]
        end
      end

      context 'pending_press_clearance state' do
        it 'shows events' do
          k = create :pending_private_clearance_ot_ico_foi
          expect(k.class).to eq Case::OverturnedICO::FOI
          expect(k.workflow).to eq 'full_approval'
          expect(k.current_state).to eq 'pending_private_office_clearance'
          expect(k.state_machine.permitted_events(press_officer.id))
            .to eq [:add_message_to_case,
                    :link_a_case,
                    :reassign_user,
                    :remove_linked_case,
                    :unflag_for_clearance]
        end
      end

      context 'awaiting_dispatch' do
        it 'shows events' do
          k = create :with_response_ot_ico_foi, :flagged_accepted, :press_office
          expect(k.class).to eq Case::OverturnedICO::FOI
          expect(k.workflow).to eq 'full_approval'
          expect(k.current_state).to eq 'awaiting_dispatch'
          expect(k.state_machine.permitted_events(press_officer.id))
            .to eq [:add_message_to_case,
                    :flag_for_clearance,
                    :link_a_case,
                    :reassign_user,
                    :remove_linked_case,
                    :unaccept_approver_assignment,
                    :unflag_for_clearance]
        end
      end

      context 'responded' do
        it 'shows events' do
          k = create :responded_full_approval_ot_ico_foi
          expect(k.class).to eq Case::OverturnedICO::FOI
          expect(k.workflow).to eq 'full_approval'
          expect(k.current_state).to eq 'responded'
          expect(k.state_machine.permitted_events(press_officer.id))
            .to eq [:add_message_to_case,
                    :link_a_case,
                    :remove_linked_case]
        end
      end

      context 'closed' do
        it 'shows events' do
          k = create :closed_full_approval_ot_ico_foi
          expect(k.class).to eq Case::OverturnedICO::FOI
          expect(k.workflow).to eq 'full_approval'
          expect(k.current_state).to eq 'closed'
          expect(k.state_machine.permitted_events(press_officer.id))
            .to eq [:add_message_to_case,
                    :link_a_case,
                    :remove_linked_case]
        end
      end

      def approver_in_assigned_team(k)
        k.approver_assignments.first.user
      end

      def assigned_disclosure_specialist!(kase)
        kase.approver_assignments.for_team(BusinessUnit.dacu_disclosure).first.user
      end

      def assigned_press_office_approver(kase)
        kase.approver_assignments.for_team(BusinessUnit.press_office).first.user
      end
    end

    ##################### APPROVER FLAGGED ############################
  end
end
