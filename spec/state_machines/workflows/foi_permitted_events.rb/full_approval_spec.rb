require 'rails_helper'

describe Case::FOI::StandardStateMachine do
  context 'full_approval workflow' do

  ##################### MANAGER FLAGGED ############################

    context 'manager' do

      let(:manager)   { create :manager}

      context 'unassigned state' do
        it 'should show permitted events' do
          k = create :case, :flagged, :press_office

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
          k = create :awaiting_responder_case, :flagged, :press_office

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
          k = create :accepted_case, :flagged, :press_office

          expect(k.current_state).to eq 'drafting'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :assign_to_new_team,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :flag_for_clearance,
                                                                      :link_a_case,
                                                                      :remove_linked_case]
        end
      end

      context 'pending_dacu_clearance' do
        it 'shows events' do
          k = create :pending_dacu_clearance_case, :flagged, :press_office

          expect(k.current_state).to eq 'pending_dacu_clearance'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :link_a_case,
                                                                      :remove_linked_case]
        end
      end

      context 'pending_press_clearance' do
        it 'shows events' do
          k = create :pending_press_clearance_case, :flagged, :press_office

          expect(k.current_state).to eq 'pending_press_office_clearance'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :extend_for_pit,
                                                                      :link_a_case,
                                                                      :remove_linked_case]
        end
      end

      context 'pending_private_clearance' do
        it 'shows events' do
          k = create :pending_private_clearance_case

          expect(k.current_state).to eq 'pending_private_office_clearance'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :extend_for_pit,
                                                                      :link_a_case,
                                                                      :remove_linked_case]
        end
      end

      context 'awaiting_dispatch' do
        it 'shows events' do
          k = create :case_with_response, :flagged, :press_office

          expect(k.current_state).to eq 'awaiting_dispatch'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :extend_for_pit,
                                                                      :flag_for_clearance,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :unflag_for_clearance]
        end
      end

      context 'responded' do
        it 'shows events' do
          k = create :responded_case, :flagged, :press_office

          expect(k.current_state).to eq 'responded'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :close,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :extend_for_pit,
                                                                      :link_a_case,
                                                                      :remove_linked_case]
        end
      end

      context 'closed' do
        it 'shows events' do
          k = create :closed_case, :flagged, :press_office

          expect(k.current_state).to eq 'closed'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:destroy_case,
                                                                      :edit_case,
                                                                      :link_a_case,
                                                                      :remove_linked_case]
        end
      end
    end


  ##################### RESPONDER FLAGGED ############################

    context 'responder' do
      context 'responder not in team' do

        let(:responder)   { create :responder }

        context 'unassigned state' do
          it 'should show permitted events' do
            k = create :case, :flagged, :press_office

            expect(k.current_state).to eq 'unassigned'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case]
          end
        end

        context 'awaiting responder state' do
          it 'shows events' do
            k = create :awaiting_responder_case, :flagged, :press_office

            expect(k.current_state).to eq 'awaiting_responder'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case,:remove_linked_case]
          end
        end

        context 'drafting state' do
          it 'shows events' do
            k = create :accepted_case, :flagged, :press_office

            expect(k.current_state).to eq 'drafting'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case,
                                                                          :remove_linked_case,
                                                                          :upload_responses]
          end
        end

        context 'pending_dacu_clearance state' do
          it 'shows events' do
            k = create :pending_dacu_clearance_case

            expect(k.current_state).to eq 'pending_dacu_clearance'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case,
                                                                          :remove_linked_case]
          end
        end

        context 'pending_press_clearance state' do
          it 'shows events' do
            k = create :pending_press_clearance_case

            expect(k.current_state).to eq 'pending_press_office_clearance'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:extend_for_pit, :link_a_case, :remove_linked_case]
          end
        end

        context 'pending_private_clearance state' do
          it 'shows events' do
            k = create :pending_private_clearance_case

            expect(k.current_state).to eq 'pending_private_office_clearance'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:extend_for_pit, :link_a_case, :remove_linked_case]
          end
        end

        context 'awaiting_dispatch' do
          it 'shows events' do
            k = create :case_with_response, :flagged, :press_office

            expect(k.current_state).to eq 'awaiting_dispatch'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:extend_for_pit,
                                                                          :link_a_case,
                                                                          :remove_linked_case]
          end
        end

        context 'responded state' do
          it 'shows events' do
            k = create :responded_case, :flagged, :press_office

            expect(k.current_state).to eq 'responded'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:extend_for_pit, :link_a_case, :remove_linked_case]
          end
        end
      end

      context 'responder in assigned team' do
        context 'awaiting_responder state' do
          it 'shows events' do
            k = create :awaiting_responder_case, :flagged, :press_office
            responder = responder_in_assigned_team(k)

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
            k = create :accepted_case, :flagged, :press_office
            responder = responder_in_assigned_team(k)

            expect(k.current_state).to eq 'drafting'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                          :add_response_to_flagged_case,
                                                                          :link_a_case,
                                                                          :reassign_user,
                                                                          :remove_linked_case,
                                                                          :upload_responses]
          end
        end

        context 'pending_dacu_clearance state' do
          it 'shows events' do
            k = create :pending_dacu_clearance_case, :flagged, :press_office
            responder = responder_in_assigned_team(k)

            expect(k.current_state).to eq 'pending_dacu_clearance'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                          :link_a_case,
                                                                          :reassign_user,
                                                                          :remove_linked_case]
          end
        end

        context 'pending_press_clearance state' do
          it 'shows events' do
            k = create :pending_press_clearance_case
            responder = responder_in_assigned_team(k)

            expect(k.current_state).to eq 'pending_press_office_clearance'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                          :extend_for_pit,
                                                                          :link_a_case,
                                                                          :reassign_user,
                                                                          :remove_linked_case]
          end
        end

        context 'pending_private_clearance state' do
          it 'shows events' do
            k = create :pending_private_clearance_case
            responder = responder_in_assigned_team(k)

            expect(k.current_state).to eq 'pending_private_office_clearance'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                          :extend_for_pit,
                                                                          :link_a_case,
                                                                          :reassign_user,
                                                                          :remove_linked_case]
          end
        end

        context 'awaiting_dispatch state' do
          it 'shows events' do
            k = create :case_with_response, :flagged, :press_office
            responder = responder_in_assigned_team(k)

            expect(k.current_state).to eq 'awaiting_dispatch'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                          :extend_for_pit,
                                                                          :link_a_case,
                                                                          :remove_last_response,
                                                                          :remove_linked_case,
                                                                          :remove_response,
                                                                          :respond]
          end
        end

        context 'responded state' do
          it 'shows events' do
            k = create :responded_case, :flagged, :press_office
            responder = responder_in_assigned_team(k)

            expect(k.current_state).to eq 'responded'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:extend_for_pit, :link_a_case, :remove_linked_case]
          end
        end

        context 'close state' do
          it 'shows events' do
            k = create :closed_case, :flagged, :press_office
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


  ##################### APPROVER FLAGGED ############################

    context 'approver' do
      context 'unassigned approver' do
        let(:team_dacu_disclosure)      { find_or_create :team_dacu_disclosure }
        let(:disclosure_specialist)     { team_dacu_disclosure.users.first }
        let(:approver)                  { disclosure_specialist }

        context 'unassigned state' do
          it 'should show permitted events' do
            k = create :case, :flagged, :press_office

            expect(k.current_state).to eq 'unassigned'
            expect(k.state_machine.permitted_events(disclosure_specialist.id)).to eq [:accept_approver_assignment,
                                                                                      :add_message_to_case,
                                                                                      :flag_for_clearance,
                                                                                      :link_a_case,
                                                                                      :remove_linked_case]
          end
        end

        context 'awaiting responder state' do
          it 'shows events' do
            k = create :awaiting_responder_case, :flagged, :press_office

            expect(k.current_state).to eq 'awaiting_responder'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:accept_approver_assignment,
                                                                         :add_message_to_case,
                                                                         :flag_for_clearance,
                                                                         :link_a_case,
                                                                         :reassign_user,
                                                                         :remove_linked_case]
          end
        end

        context 'drafting state' do
          it 'shows events' do
            k = create :accepted_case, :flagged, :press_office

            expect(k.current_state).to eq 'drafting'
            expect(k.state_machine.permitted_events(approver.id)).to eq [ :accept_approver_assignment,
                                                                          :add_message_to_case,
                                                                          :flag_for_clearance,
                                                                          :link_a_case,
                                                                          :reassign_user,
                                                                          :remove_linked_case]
          end
        end

        context 'pending_dacu_clearance state' do
          it 'shows events' do
            k = create :pending_dacu_clearance_case, :flagged, :press_office

            expect(k.current_state).to eq 'pending_dacu_clearance'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:accept_approver_assignment,
                                                                         :add_message_to_case,
                                                                         :link_a_case,
                                                                         :reassign_user,
                                                                         :remove_linked_case]
          end
        end

        context 'pending_press_clearance state' do
          it 'shows events' do
            k = create :pending_press_clearance_case, :flagged, :press_office

            expect(k.current_state).to eq 'pending_press_office_clearance'
            expect(k.state_machine.permitted_events(approver.id)).to eq [ :add_message_to_case,
                                                                          :extend_for_pit,
                                                                          :link_a_case,
                                                                          :remove_linked_case]
          end
        end

        context 'pending_private_clearance state' do
          it 'shows events' do
            k = create :pending_private_clearance_case, :flagged, :press_office

            expect(k.current_state).to eq 'pending_private_office_clearance'
            expect(k.state_machine.permitted_events(approver.id)).to eq [ :add_message_to_case,
                                                                          :extend_for_pit,
                                                                          :link_a_case,
                                                                          :remove_linked_case]
          end
        end

        context 'awaiting_dispatch' do
          it 'shows events' do
            # this needs to be corrected when switched to config state machine - no request further clearance or extend for pit
            k = create :case_with_response, :flagged, :press_office

            expect(k.current_state).to eq 'awaiting_dispatch'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:accept_approver_assignment,
                                                                         :add_message_to_case,
                                                                         :extend_for_pit,
                                                                         :flag_for_clearance,
                                                                         :link_a_case,
                                                                         :remove_linked_case,
                                                                         :unflag_for_clearance]
          end
        end

        context 'responded' do
          it 'shows events' do
            k = create :responded_case, :flagged, :press_office

            expect(k.current_state).to eq 'responded'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:accept_approver_assignment,
                                                                         :add_message_to_case,
                                                                         :extend_for_pit,
                                                                         :link_a_case,
                                                                         :remove_linked_case]
          end
        end

        context 'closed' do
          it 'shows events' do
            k = create :closed_case, :flagged, :press_office

            expect(k.current_state).to eq 'closed'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:link_a_case, :remove_linked_case]
          end
        end
      end
    end


  ##################### APPROVER FLAGGED ############################

    context 'assigned approver' do
      context 'unassigned state' do

        it 'should show permitted events' do
          k = create :case, :flagged_accepted, :press_office
          approver = approver_in_assigned_team(k)
          expect(k.current_state).to eq 'unassigned'
          expect(k.state_machine.permitted_events(approver.id)).to eq [ :add_message_to_case,
                                                                        :flag_for_clearance,
                                                                        :link_a_case,
                                                                        :reassign_user,
                                                                        :remove_linked_case,
                                                                        :unflag_for_clearance]
        end
      end

      context 'awaiting responder state' do
        it 'shows events' do
          k = create :awaiting_responder_case, :flagged_accepted, :press_office
          approver = approver_in_assigned_team(k)
          expect(k.current_state).to eq 'awaiting_responder'
          expect(k.state_machine.permitted_events(approver.id)).to eq [:add_message_to_case,
                                                                       :flag_for_clearance,
                                                                       :link_a_case,
                                                                       :reassign_user,
                                                                       :remove_linked_case,
                                                                       :unflag_for_clearance]
        end
      end

      context 'drafting state' do
        it 'shows events' do
          k = create :accepted_case, :flagged_accepted, :press_office
          approver = approver_in_assigned_team(k)

          expect(k.current_state).to eq 'drafting'
          expect(k.state_machine.permitted_events(approver.id)).to eq [:add_message_to_case,
                                                                       :flag_for_clearance,
                                                                       :link_a_case,
                                                                       :reassign_user,
                                                                       :remove_linked_case,
                                                                       :unflag_for_clearance]
        end
      end

      context 'pending_dacu_clearance state' do
        it 'shows events' do
          k = create :pending_dacu_clearance_case, :flagged_accepted, :press_office
          approver = approver_in_assigned_team(k)

          expect(k.current_state).to eq 'pending_dacu_clearance'
          expect(k.state_machine.permitted_events(approver.id)).to eq [ :add_message_to_case,
                                                                        :link_a_case,
                                                                        :reassign_user,
                                                                        :remove_linked_case,
                                                                        :unflag_for_clearance]
        end
      end

      context 'pending_press_clearance state' do
        it 'shows events' do
          k = create :pending_press_clearance_case
          approver = approver_in_assigned_team(k)

          expect(k.current_state).to eq 'pending_press_office_clearance'
          expect(k.state_machine.permitted_events(approver.id)).to eq [:add_message_to_case,
                                                                       :extend_for_pit,
                                                                       :link_a_case,
                                                                       :reassign_user,
                                                                       :remove_linked_case]
        end
      end

      context 'pending_press_clearance state' do
        it 'shows events' do
          k = create :pending_private_clearance_case
          approver = approver_in_assigned_team(k)

          expect(k.current_state).to eq 'pending_private_office_clearance'
          expect(k.state_machine.permitted_events(approver.id)).to eq [:add_message_to_case,
                                                                       :extend_for_pit,
                                                                       :link_a_case,
                                                                       :reassign_user,
                                                                       :remove_linked_case]
        end
      end

      context 'awaiting_dispatch' do
        it 'shows events' do
          k = create :case_with_response, :flagged_accepted, :press_office
          approver = approver_in_assigned_team(k)
          expect(k.current_state).to eq 'awaiting_dispatch'
          expect(k.state_machine.permitted_events(approver.id)).to eq [:add_message_to_case,
                                                                       :extend_for_pit,
                                                                       :flag_for_clearance,
                                                                       :link_a_case,
                                                                       :remove_linked_case,
                                                                       :unaccept_approver_assignment,
                                                                       :unflag_for_clearance]
        end
      end

      context 'responded' do
        it 'shows events' do
          k = create :responded_case, :flagged_accepted, :press_office
          approver = approver_in_assigned_team(k)
          expect(k.current_state).to eq 'responded'
          expect(k.state_machine.permitted_events(approver.id)).to eq [:add_message_to_case,
                                                                       :extend_for_pit,
                                                                       :link_a_case,
                                                                       :remove_linked_case]
        end
      end

      context 'closed' do
        it 'shows events' do
          k = create :closed_case, :flagged_accepted, :press_office
          approver = approver_in_assigned_team(k)
          expect(k.current_state).to eq 'closed'
          expect(k.state_machine.permitted_events(approver.id)).to eq [:link_a_case, :remove_linked_case]
        end
      end

      def approver_in_assigned_team(k)
        k.approver_assignments.first.user
      end
    end
  end
end
