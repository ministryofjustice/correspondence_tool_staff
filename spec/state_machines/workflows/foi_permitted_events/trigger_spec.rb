require 'rails_helper'

describe ConfigurableStateMachine::Machine do
  context 'trigger workflow' do

  ##################### MANAGER FLAGGED ############################

    context 'manager' do

      let(:manager)   { create :manager}

      context 'unassigned state' do
        it 'should show permitted events' do
          k = create :case, :flagged, :dacu_disclosure

          expect(k.current_state).to eq 'unassigned'
          expect(k.state_machine.permitted_events(manager)).to eq [ :add_message_to_case,
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
          k = create :awaiting_responder_case, :flagged, :dacu_disclosure

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
          k = create :accepted_case, :flagged, :dacu_disclosure

          expect(k.current_state).to eq 'drafting'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :assign_to_new_team,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :extend_for_pit,
                                                                      :flag_for_clearance,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :request_further_clearance]
        end
      end

      context 'pending_dacu_clearance' do
        it 'shows events' do
          k = create :pending_dacu_clearance_case, :flagged, :dacu_disclosure

          expect(k.current_state).to eq 'pending_dacu_clearance'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :extend_for_pit,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :request_further_clearance]
        end
      end

      context 'awaiting_dispatch' do
        it 'shows events' do
          k = create :case_with_response, :flagged, :dacu_disclosure

          expect(k.current_state).to eq 'awaiting_dispatch'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :extend_for_pit,
                                                                      :flag_for_clearance,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :request_further_clearance]
        end
      end

      context 'responded' do
        it 'shows events' do
          k = create :responded_case, :flagged, :dacu_disclosure

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
          k = create :closed_case, :flagged, :dacu_disclosure

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
            k = create :case, :flagged, :dacu_disclosure

            expect(k.current_state).to eq 'unassigned'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case, :remove_linked_case]
          end
        end

        context 'awaiting responder state' do
          it 'shows events' do
            k = create :awaiting_responder_case, :flagged, :dacu_disclosure

            expect(k.current_state).to eq 'awaiting_responder'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case,:remove_linked_case]
          end
        end

        context 'drafting state' do
          it 'shows events' do
            k = create :accepted_case, :flagged, :dacu_disclosure

            expect(k.current_state).to eq 'drafting'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case,
                                                                          :remove_linked_case]
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

        context 'awaiting_dispatch' do
          it 'shows events' do
            k = create :case_with_response, :flagged, :dacu_disclosure

            expect(k.current_state).to eq 'awaiting_dispatch'
            expect(k.workflow).to eq 'trigger'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case,
                                                                          :remove_linked_case]
          end
        end

        context 'responded state' do
          it 'shows events' do
            k = create :responded_case, :flagged, :dacu_disclosure

            expect(k.current_state).to eq 'responded'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case, :remove_linked_case]
          end
        end
      end

      context 'responder in assigned team' do
        context 'awaiting_responder state' do
          it 'shows events' do
            k = create :awaiting_responder_case, :flagged, :dacu_disclosure
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
            k = create :accepted_case, :flagged, :dacu_disclosure
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
            k = create :pending_dacu_clearance_case, :flagged, :dacu_disclosure
            responder = responder_in_assigned_team(k)

            expect(k.current_state).to eq 'pending_dacu_clearance'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                          :link_a_case,
                                                                          :reassign_user,
                                                                          :remove_linked_case]
          end
        end

        context 'awaiting_dispatch state' do
          it 'shows events' do
            k = create :case_with_response, :flagged, :dacu_disclosure
            responder = responder_in_assigned_team(k)

            expect(k.current_state).to eq 'awaiting_dispatch'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                          :add_responses,
                                                                          :link_a_case,
                                                                          :reassign_user,
                                                                          :remove_last_response,
                                                                          :remove_linked_case,
                                                                          :remove_response,
                                                                          :respond]
          end
        end

        context 'responded state' do
          it 'shows events' do
            k = create :responded_case, :flagged, :dacu_disclosure
            responder = responder_in_assigned_team(k)

            expect(k.current_state).to eq 'responded'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case, :link_a_case, :remove_linked_case]
          end
        end

        context 'close state' do
          it 'shows events' do
            k = create :closed_case, :flagged, :dacu_disclosure
            responder = responder_in_assigned_team(k)

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
      context 'unassigned approver' do
        let(:team_dacu_disclosure)      { find_or_create :team_dacu_disclosure }
        let(:disclosure_specialist)     { team_dacu_disclosure.users.first }
        let(:approver)                  { disclosure_specialist }

        context 'unassigned state' do
          it 'should show permitted events' do
            k = create :case, :flagged, :dacu_disclosure

            expect(k.current_state).to eq 'unassigned'
            expect(k.state_machine.permitted_events(disclosure_specialist.id)).to eq [:accept_approver_assignment,
                                                                                      :add_message_to_case,
                                                                                      :flag_for_clearance,
                                                                                      :link_a_case,
                                                                                      :remove_linked_case,
                                                                                      :unflag_for_clearance]
          end
        end

        context 'awaiting responder state' do
          it 'shows events' do
            k = create :awaiting_responder_case, :flagged, :dacu_disclosure

            expect(k.current_state).to eq 'awaiting_responder'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:accept_approver_assignment,
                                                                         :add_message_to_case,
                                                                         :flag_for_clearance,
                                                                         :link_a_case,
                                                                         :reassign_user,
                                                                         :remove_linked_case,
                                                                         :unflag_for_clearance]
          end
        end

        context 'drafting state' do
          it 'shows events' do
            k = create :accepted_case, :flagged, :dacu_disclosure

            expect(k.current_state).to eq 'drafting'
            expect(k.state_machine.permitted_events(approver.id)).to eq [ :accept_approver_assignment,
                                                                          :add_message_to_case,
                                                                          :flag_for_clearance,
                                                                          :link_a_case,
                                                                          :reassign_user,
                                                                          :remove_linked_case,
                                                                          :unflag_for_clearance]
          end
        end

        context 'pending_dacu_clearance state' do
          it 'shows events' do
            k = create :pending_dacu_clearance_case, :dacu_disclosure
            unassigned_approver = create :approver

            expect(k.current_state).to eq 'pending_dacu_clearance'
            expect(k.state_machine.permitted_events(unassigned_approver.id)).to eq [ :add_message_to_case,
                                                                                     :link_a_case,
                                                                                     :reassign_user,
                                                                                     :remove_linked_case]
          end
        end

        context 'awaiting_dispatch' do
          it 'shows events' do
            # this needs to be corrected when switched to config state machine - no request further clearance or extend for pit
            k = create :case_with_response, :flagged, :dacu_disclosure

            expect(k.current_state).to eq 'awaiting_dispatch'
            expect(k.workflow).to eq 'trigger'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:link_a_case,
                                                                         :remove_linked_case]
          end
        end

        context 'responded' do
          it 'shows events' do
            k = create :responded_case, :flagged, :dacu_disclosure

            expect(k.current_state).to eq 'responded'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:link_a_case,
                                                                         :remove_linked_case]
          end
        end

        context 'closed' do
          it 'shows events' do
            k = create :closed_case, :flagged, :dacu_disclosure

            expect(k.current_state).to eq 'closed'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:add_message_to_case,
                                                                         :link_a_case,
                                                                         :remove_linked_case]
          end
        end
      end
    end


  ##################### APPROVER FLAGGED ############################

    context 'assigned approver' do
      context 'unassigned state' do

        it 'should show permitted events' do
          k = create :case, :flagged_accepted, :dacu_disclosure
          approver = approver_in_assigned_team(k)
          expect(k.current_state).to eq 'unassigned'
          expect(k.state_machine.permitted_events(approver.id)).to eq [ :add_message_to_case,
                                                                        :flag_for_clearance,
                                                                        :link_a_case,
                                                                        :reassign_user,
                                                                        :remove_linked_case,
                                                                        :unaccept_approver_assignment,
                                                                        :unflag_for_clearance]
        end
      end

      context 'awaiting responder state' do
        it 'shows events' do
          k = create :awaiting_responder_case, :flagged_accepted, :dacu_disclosure
          approver = approver_in_assigned_team(k)
          expect(k.current_state).to eq 'awaiting_responder'
          expect(k.state_machine.permitted_events(approver.id)).to eq [:add_message_to_case,
                                                                       :flag_for_clearance,
                                                                       :link_a_case,
                                                                       :reassign_user,
                                                                       :remove_linked_case,
                                                                       :unaccept_approver_assignment,
                                                                       :unflag_for_clearance]
        end
      end

      context 'drafting state' do
        it 'shows events' do
          k = create :accepted_case, :flagged_accepted, :dacu_disclosure
          approver = approver_in_assigned_team(k)

          expect(k.current_state).to eq 'drafting'
          expect(k.state_machine.permitted_events(approver.id)).to eq [:add_message_to_case,
                                                                       :flag_for_clearance,
                                                                       :link_a_case,
                                                                       :reassign_user,
                                                                       :remove_linked_case,
                                                                       :unaccept_approver_assignment,
                                                                       :unflag_for_clearance]
        end
      end

      context 'pending_dacu_clearance state' do
        it 'shows events' do
          k = create :pending_dacu_clearance_case, :flagged_accepted, :dacu_disclosure
          approver = approver_in_assigned_team(k)

          expect(k.current_state).to eq 'pending_dacu_clearance'
          expect(k.state_machine.permitted_events(approver.id)).to eq [ :add_message_to_case,
                                                                        :approve,
                                                                        :link_a_case,
                                                                        :reassign_user,
                                                                        :remove_linked_case,
                                                                        :unaccept_approver_assignment,
                                                                        :upload_response_and_approve,
                                                                        :upload_response_and_return_for_redraft]
        end
      end

      context 'awaiting_dispatch' do
        it 'shows events' do
          k = create :case_with_response, :flagged_accepted, :dacu_disclosure
          approver = approver_in_assigned_team(k)
          expect(k.current_state).to eq 'awaiting_dispatch'
          expect(k.workflow).to eq 'trigger'
          expect(k.state_machine.permitted_events(approver.id)).to eq [:add_message_to_case,
                                                                       :link_a_case,
                                                                       :reassign_user,
                                                                       :remove_linked_case]
        end
      end

      context 'responded' do
        it 'shows events' do
          k = create :responded_case, :flagged_accepted, :dacu_disclosure
          approver = approver_in_assigned_team(k)
          expect(k.current_state).to eq 'responded'
          expect(k.state_machine.permitted_events(approver.id)).to eq [:add_message_to_case,
                                                                       :link_a_case,
                                                                       :remove_linked_case]
        end
      end

      context 'closed' do
        it 'shows events' do
          k = create :closed_case, :flagged_accepted, :dacu_disclosure
          approver = approver_in_assigned_team(k)
          expect(k.current_state).to eq 'closed'
          expect(k.state_machine.permitted_events(approver.id)).to eq [:add_message_to_case,
                                                                       :link_a_case,
                                                                       :remove_linked_case]
        end
      end

      def approver_in_assigned_team(k)
        k.approver_assignments.first.user
      end
    end
  end
end
