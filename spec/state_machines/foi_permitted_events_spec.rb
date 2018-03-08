require 'rails_helper'

describe Case::FOI::StandardStateMachine do
  context 'non-flagged case' do

##################### MANAGER UNFLAGGED ############################

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
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :link_a_case,
                                                                      :remove_linked_case]
        end
      end
    end


##################### RESPONDER UNFLAGGED ############################

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
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case, :link_a_case, :remove_linked_case]
          end
        end

        context 'awaiting_dispatch' do
          it 'shows events' do
            k = create :case_with_response

            expect(k.current_state).to eq 'awaiting_dispatch'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                          :link_a_case,
                                                                          :remove_linked_case]
          end
        end

        context 'responded state' do
          it 'shows events' do
            k = create :responded_case

            expect(k.current_state).to eq 'responded'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case, :link_a_case, :remove_linked_case]
          end
        end
        context 'closed state' do
          it 'shows events' do
            k = create :closed_case

            expect(k.current_state).to eq 'closed'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case]
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
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case, :link_a_case, :remove_linked_case]
          end
        end

        context 'closed state' do
          it 'shows events' do
            k = create :closed_case
            responder = responder_in_assigned_team(k)

            expect(k.current_state).to eq 'closed'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case]
          end
        end
      end

      def responder_in_assigned_team(k)
        create :responder, responding_teams: [k.responding_team]
      end
    end


##################### APPROVER UNFLAGGED ############################


    context 'approver' do
      context 'unassigned approver' do
        let(:approver)   { create :approver}

        context 'unassigned state' do
          it 'should show permitted events' do
            k = create :case

            expect(k.current_state).to eq 'unassigned'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:accept_approver_assignment, :flag_for_clearance]

          end
        end

        context 'awaiting responder state' do
          it 'shows events' do
            k = create :awaiting_responder_case

            expect(k.current_state).to eq 'awaiting_responder'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:accept_approver_assignment,
                                                                         :flag_for_clearance,
                                                                         :link_a_case,
                                                                         :remove_linked_case,
                                                                         :take_on_for_approval,
                                                                         :unflag_for_clearance]
          end
        end

        context 'drafting state' do
          it 'shows events' do
            k = create :accepted_case

            expect(k.current_state).to eq 'drafting'
            expect(k.state_machine.permitted_events(approver.id)).to eq [ :add_message_to_case,
                                                                          :link_a_case,
                                                                          :remove_linked_case,
                                                                          :take_on_for_approval]
          end
        end

        context 'awaiting_dispatch' do
          it 'shows events' do
            k = create :case_with_response

            expect(k.current_state).to eq 'awaiting_dispatch'
            expect(k.state_machine.permitted_events(approver.id)).to eq [ :add_message_to_case,
                                                                          :link_a_case,
                                                                          :remove_linked_case,
                                                                          :take_on_for_approval]
          end
        end

        context 'responded' do
          it 'shows events' do
            k = create :responded_case

            expect(k.current_state).to eq 'responded'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:add_message_to_case, :link_a_case, :remove_linked_case]
          end
        end

        context 'closed' do
          it 'shows events' do
            k = create :closed_case

            expect(k.current_state).to eq 'closed'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:add_message_to_case, :link_a_case]
          end
        end
      end
    end
  end



  context 'flagged case' do

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
                                                                    :request_further_clearance,
                                                                    :unflag_for_clearance]
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
                                                                      :request_further_clearance,
                                                                      :unflag_for_clearance]
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
                                                                      :flag_for_clearance,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :request_further_clearance,
                                                                      :unflag_for_clearance]
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
                                                                      :request_further_clearance,
                                                                      :unflag_for_clearance]
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
                                                                      :extend_for_pit,
                                                                      :link_a_case,
                                                                      :remove_linked_case]
        end
      end

      context 'closed' do
        it 'shows events' do
          k = create :closed_case, :flagged, :dacu_disclosure

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
            k = create :case, :flagged, :dacu_disclosure

            expect(k.current_state).to eq 'unassigned'
            expect(k.state_machine.permitted_events(responder.id)).to be_empty #should include link_a_case
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
                                                                          :remove_linked_case,
                                                                          :upload_responses]
          end
        end

        context 'awaiting_dispatch' do
          it 'shows events' do
            k = create :case_with_response, :flagged, :dacu_disclosure

            expect(k.current_state).to eq 'awaiting_dispatch'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:extend_for_pit,
                                                                          :link_a_case,
                                                                          :remove_linked_case,
                                                                          :request_further_clearance]
          end
        end

        context 'responded state' do
          it 'shows events' do
            k = create :responded_case, :flagged, :dacu_disclosure

            expect(k.current_state).to eq 'responded'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:extend_for_pit, :link_a_case, :remove_linked_case]
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

        context 'awaiting_dispatch state' do
          it 'shows events' do
            k = create :case_with_response, :flagged, :dacu_disclosure
            responder = responder_in_assigned_team(k)

            expect(k.current_state).to eq 'awaiting_dispatch'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                          :extend_for_pit,
                                                                          :link_a_case,
                                                                          :remove_last_response,
                                                                          :remove_linked_case,
                                                                          :remove_response,
                                                                          :request_further_clearance,
                                                                          :respond]
          end
        end

        context 'responded state' do
          it 'shows events' do
            k = create :responded_case, :flagged, :dacu_disclosure
            responder = responder_in_assigned_team(k)

            expect(k.current_state).to eq 'responded'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:extend_for_pit, :link_a_case, :remove_linked_case]
          end
        end

        context 'close state' do
          it 'shows events' do
            k = create :closed_case, :flagged, :dacu_disclosure
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

        context 'awaiting_dispatch' do
          it 'shows events' do
            # this needs to be corrected when switched to config state machine - no request further clearance or extend for pit
            k = create :case_with_response, :flagged, :dacu_disclosure

            expect(k.current_state).to eq 'awaiting_dispatch'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:accept_approver_assignment,
                                                                         :add_message_to_case,
                                                                         :extend_for_pit,
                                                                         :flag_for_clearance,
                                                                         :link_a_case,
                                                                         :remove_linked_case,
                                                                         :request_further_clearance,
                                                                         :unflag_for_clearance]
          end
        end

        context 'responded' do
          it 'shows events' do
            k = create :responded_case, :flagged, :dacu_disclosure

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
            k = create :closed_case, :flagged, :dacu_disclosure

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
                                                                       :extend_for_pit,
                                                                       :flag_for_clearance,
                                                                       :link_a_case,
                                                                       :reassign_user,
                                                                       :remove_linked_case,
                                                                       :unaccept_approver_assignment,
                                                                       :unflag_for_clearance]
        end
      end

      context 'awaiting_dispatch' do
        it 'shows events' do
          k = create :case_with_response, :flagged_accepted, :dacu_disclosure
          approver = approver_in_assigned_team(k)
          expect(k.current_state).to eq 'awaiting_dispatch'
          expect(k.state_machine.permitted_events(approver.id)).to eq [:add_message_to_case,
                                                                       :extend_for_pit,
                                                                       :flag_for_clearance,
                                                                       :link_a_case,
                                                                       :remove_linked_case,
                                                                       :request_further_clearance,
                                                                       :unaccept_approver_assignment,
                                                                       :unflag_for_clearance]
        end
      end

      context 'responded' do
        it 'shows events' do
          k = create :responded_case, :flagged_accepted, :dacu_disclosure
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
          k = create :closed_case, :flagged_accepted, :dacu_disclosure
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
