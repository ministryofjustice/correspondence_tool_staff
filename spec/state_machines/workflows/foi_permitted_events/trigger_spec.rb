require "rails_helper"

describe ConfigurableStateMachine::Machine do
  describe "trigger workflow" do
    ##################### MANAGER FLAGGED ############################

    ##################### APPROVER FLAGGED ############################
    let(:approver) { find_or_create :disclosure_specialist }

    context "when manager" do
      let(:manager)   { create :manager }

      context "and unassigned state" do
        it "shows permitted events" do
          k = create :case, :flagged, :dacu_disclosure

          expect(k.current_state).to eq "unassigned"
          expect(k.state_machine.permitted_events(manager)).to eq %i[add_message_to_case
                                                                     assign_responder
                                                                     destroy_case
                                                                     edit_case
                                                                     flag_for_clearance
                                                                     link_a_case
                                                                     remove_linked_case
                                                                     request_further_clearance]
        end
      end

      context "and awaiting responder state" do
        it "shows events" do
          k = create :awaiting_responder_case, :flagged, :dacu_disclosure

          expect(k.current_state).to eq "awaiting_responder"
          expect(k.state_machine.permitted_events(manager.id)).to eq %i[add_message_to_case
                                                                        assign_to_new_team
                                                                        destroy_case
                                                                        edit_case
                                                                        flag_for_clearance
                                                                        link_a_case
                                                                        remove_linked_case
                                                                        request_further_clearance]
        end
      end

      context "and drafting state" do
        it "shows events" do
          k = create :accepted_case, :flagged, :dacu_disclosure

          expect(k.current_state).to eq "drafting"
          expect(k.state_machine.permitted_events(manager.id)).to eq %i[add_message_to_case
                                                                        assign_to_new_team
                                                                        destroy_case
                                                                        edit_case
                                                                        extend_for_pit
                                                                        flag_for_clearance
                                                                        link_a_case
                                                                        remove_linked_case
                                                                        request_further_clearance
                                                                        unassign_from_user]
        end
      end

      context "and pending_dacu_clearance" do
        it "shows events" do
          k = create :pending_dacu_clearance_case, :flagged, :dacu_disclosure

          expect(k.current_state).to eq "pending_dacu_clearance"
          expect(k.state_machine.permitted_events(manager.id)).to eq %i[add_message_to_case
                                                                        destroy_case
                                                                        edit_case
                                                                        extend_for_pit
                                                                        link_a_case
                                                                        remove_linked_case
                                                                        request_further_clearance
                                                                        unassign_from_user]
        end
      end

      context "and awaiting_dispatch" do
        it "shows events - not member of case managing team" do
          k = create :case_with_response, :flagged, :dacu_disclosure

          expect(k.current_state).to eq "awaiting_dispatch"
          expect(k.state_machine.permitted_events(manager.id))
            .to eq %i[add_message_to_case
                      destroy_case
                      edit_case
                      extend_for_pit
                      flag_for_clearance
                      link_a_case
                      remove_linked_case
                      request_further_clearance
                      unassign_from_user]
        end

        it "shows events - member of case managing team" do
          k = create :case_with_response, :flagged, :dacu_disclosure

          expect(k.current_state).to eq "awaiting_dispatch"
          expect(k.state_machine.permitted_events(k.managing_team.users.first.id))
            .to eq %i[add_message_to_case
                      destroy_case
                      edit_case
                      extend_for_pit
                      flag_for_clearance
                      link_a_case
                      remove_linked_case
                      request_further_clearance
                      send_back
                      unassign_from_user]
        end
      end

      context "and responded" do
        it "shows events - not member of case managing team" do
          k = create :responded_case, :flagged, :dacu_disclosure

          expect(k.current_state).to eq "responded"
          expect(k.state_machine.permitted_events(manager.id))
          .to eq %i[add_message_to_case
                    close
                    destroy_case
                    edit_case
                    link_a_case
                    remove_linked_case
                    unassign_from_user]
        end

        it "shows events - member of case managing team" do
          k = create :responded_case, :flagged, :dacu_disclosure

          expect(k.current_state).to eq "responded"
          expect(k.state_machine.permitted_events(k.managing_team.users.first.id))
          .to eq %i[add_message_to_case
                    close
                    destroy_case
                    edit_case
                    link_a_case
                    remove_linked_case
                    send_back
                    unassign_from_user]
        end
      end

      context "and closed" do
        it "shows events" do
          k = create :closed_case, :flagged, :dacu_disclosure

          expect(k.current_state).to eq "closed"
          expect(k.state_machine.permitted_events(manager.id)).to eq %i[add_message_to_case
                                                                        assign_to_new_team
                                                                        destroy_case
                                                                        edit_case
                                                                        link_a_case
                                                                        remove_linked_case
                                                                        update_closure]
        end
      end
    end

    ##################### RESPONDER FLAGGED ############################

    context "when responder" do
      context "and responder not in team" do
        let(:responder) { create :responder }

        context "and unassigned state" do
          it "shows permitted events" do
            k = create :case, :flagged, :dacu_disclosure

            expect(k.current_state).to eq "unassigned"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[link_a_case remove_linked_case]
          end
        end

        context "and awaiting responder state" do
          it "shows events" do
            k = create :awaiting_responder_case, :flagged, :dacu_disclosure

            expect(k.current_state).to eq "awaiting_responder"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[link_a_case remove_linked_case]
          end
        end

        context "and drafting state" do
          it "shows events" do
            k = create :accepted_case, :flagged, :dacu_disclosure

            expect(k.current_state).to eq "drafting"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[link_a_case
                                                                            remove_linked_case]
          end
        end

        context "and pending_dacu_clearance state" do
          it "shows events" do
            k = create :pending_dacu_clearance_case

            expect(k.current_state).to eq "pending_dacu_clearance"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[link_a_case
                                                                            remove_linked_case]
          end
        end

        context "and awaiting_dispatch" do
          it "shows events" do
            k = create :case_with_response, :flagged, :dacu_disclosure

            expect(k.current_state).to eq "awaiting_dispatch"
            expect(k.workflow).to eq "trigger"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[link_a_case
                                                                            remove_linked_case]
          end
        end

        context "and responded state" do
          it "shows events" do
            k = create :responded_case, :flagged, :dacu_disclosure

            expect(k.current_state).to eq "responded"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[link_a_case remove_linked_case]
          end
        end
      end

      context "and responder in assigned team" do
        context "and awaiting_responder state" do
          it "shows events" do
            k = create :awaiting_responder_case, :flagged, :dacu_disclosure
            responder = responder_in_assigned_team(k)
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "trigger"
            expect(k.current_state).to eq "awaiting_responder"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[accept_responder_assignment
                                                                            add_message_to_case
                                                                            link_a_case
                                                                            reject_responder_assignment
                                                                            remove_linked_case]
          end
        end

        context "and drafting state" do
          it "shows events" do
            k = create :accepted_case, :flagged, :dacu_disclosure
            responder = responder_in_assigned_team(k)
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "trigger"
            expect(k.current_state).to eq "drafting"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[add_message_to_case
                                                                            add_responses
                                                                            link_a_case
                                                                            reassign_user
                                                                            remove_linked_case
                                                                            remove_response
                                                                            upload_responses]
          end
        end

        context "and pending_dacu_clearance state" do
          it "shows events" do
            k = create :pending_dacu_clearance_case, :flagged, :dacu_disclosure
            responder = responder_in_assigned_team(k)
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "trigger"
            expect(k.current_state).to eq "pending_dacu_clearance"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[add_message_to_case
                                                                            link_a_case
                                                                            reassign_user
                                                                            remove_linked_case]
          end
        end

        context "and awaiting_dispatch state" do
          it "shows events" do
            k = create :case_with_response, :flagged, :dacu_disclosure
            responder = responder_in_assigned_team(k)
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "trigger"
            expect(k.current_state).to eq "awaiting_dispatch"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[add_message_to_case
                                                                            add_responses
                                                                            link_a_case
                                                                            reassign_user
                                                                            remove_last_response
                                                                            remove_linked_case
                                                                            remove_response
                                                                            respond]
          end
        end

        context "and responded state" do
          it "shows events" do
            k = create :responded_case, :flagged, :dacu_disclosure
            responder = responder_in_assigned_team(k)
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "trigger"
            expect(k.current_state).to eq "responded"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[add_message_to_case link_a_case remove_linked_case]
          end
        end

        context "and close state" do
          it "shows events" do
            k = create :closed_case, :flagged, :dacu_disclosure
            responder = responder_in_assigned_team(k)
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "trigger"
            expect(k.current_state).to eq "closed"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[add_message_to_case
                                                                            link_a_case
                                                                            remove_linked_case]
          end
        end
      end

      def responder_in_assigned_team(k)
        create :responder, responding_teams: [k.responding_team]
      end
    end

    ##################### APPROVER FLAGGED ############################

    context "when approver" do
      context "and unassigned approver" do
        let(:team_dacu_disclosure)      { find_or_create :team_dacu_disclosure }
        let(:disclosure_specialist)     { team_dacu_disclosure.users.first }
        let(:approver)                  { disclosure_specialist }

        context "and unassigned state" do
          it "shows permitted events" do
            k = create :case, :flagged, :dacu_disclosure
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "trigger"
            expect(k.current_state).to eq "unassigned"
            expect(k.state_machine.permitted_events(disclosure_specialist.id)).to eq %i[accept_approver_assignment
                                                                                        add_message_to_case
                                                                                        flag_for_clearance
                                                                                        link_a_case
                                                                                        remove_linked_case
                                                                                        unflag_for_clearance]
          end
        end

        context "and awaiting responder state" do
          it "shows events" do
            k = create :awaiting_responder_case, :flagged, :dacu_disclosure
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "trigger"
            expect(k.current_state).to eq "awaiting_responder"
            expect(k.state_machine.permitted_events(approver.id)).to eq %i[accept_approver_assignment
                                                                           add_message_to_case
                                                                           flag_for_clearance
                                                                           link_a_case
                                                                           reassign_user
                                                                           remove_linked_case
                                                                           unflag_for_clearance]
          end
        end

        context "and drafting state" do
          it "shows events" do
            k = create :accepted_case, :flagged, :dacu_disclosure
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "trigger"
            expect(k.current_state).to eq "drafting"
            expect(k.state_machine.permitted_events(approver.id)).to eq %i[accept_approver_assignment
                                                                           add_message_to_case
                                                                           flag_for_clearance
                                                                           link_a_case
                                                                           reassign_user
                                                                           remove_linked_case
                                                                           unflag_for_clearance]
          end
        end

        context "and pending_dacu_clearance state" do
          it "shows events" do
            k = create :pending_dacu_clearance_case, :dacu_disclosure
            unassigned_approver = create :approver
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "trigger"
            expect(k.current_state).to eq "pending_dacu_clearance"
            expect(k.state_machine.permitted_events(unassigned_approver.id)).to eq %i[add_message_to_case
                                                                                      link_a_case
                                                                                      reassign_user
                                                                                      remove_linked_case]
          end
        end

        context "and awaiting_dispatch" do
          it "shows events" do
            # this needs to be corrected when switched to config state machine - no request further clearance or extend for pit
            k = create :case_with_response, :flagged, :dacu_disclosure
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "trigger"
            expect(k.current_state).to eq "awaiting_dispatch"
            expect(k.state_machine.permitted_events(approver.id)).to eq %i[link_a_case
                                                                           remove_linked_case]
          end
        end

        context "and responded" do
          it "shows events" do
            k = create :responded_case, :flagged, :dacu_disclosure
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "trigger"
            expect(k.current_state).to eq "responded"
            expect(k.state_machine.permitted_events(approver.id)).to eq %i[link_a_case
                                                                           remove_linked_case]
          end
        end

        context "and closed" do
          it "shows events" do
            k = create :closed_case, :flagged, :dacu_disclosure
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "trigger"
            expect(k.current_state).to eq "closed"
            expect(k.state_machine.permitted_events(approver.id)).to eq %i[add_message_to_case
                                                                           link_a_case
                                                                           remove_linked_case]
          end
        end
      end
    end

    context "when assigned disclosure approver" do
      context "and unassigned state" do
        it "shows permitted events" do
          k = create :case, :flagged_accepted, :dacu_disclosure
          expect(k.class).to eq Case::FOI::Standard
          expect(k.workflow).to eq "trigger"
          expect(k.current_state).to eq "unassigned"
          expect(k.state_machine.permitted_events(approver.id)).to eq %i[add_message_to_case
                                                                         flag_for_clearance
                                                                         link_a_case
                                                                         reassign_user
                                                                         remove_linked_case
                                                                         unaccept_approver_assignment
                                                                         unflag_for_clearance]
        end
      end

      context "and awaiting responder state" do
        it "shows events" do
          k = create :awaiting_responder_case, :flagged_accepted, :dacu_disclosure
          expect(k.class).to eq Case::FOI::Standard
          expect(k.workflow).to eq "trigger"
          expect(k.current_state).to eq "awaiting_responder"
          expect(k.state_machine.permitted_events(approver.id)).to eq %i[add_message_to_case
                                                                         flag_for_clearance
                                                                         link_a_case
                                                                         reassign_user
                                                                         remove_linked_case
                                                                         unaccept_approver_assignment
                                                                         unflag_for_clearance]
        end
      end

      context "and drafting state" do
        it "shows events" do
          k = create :accepted_case, :flagged_accepted, :dacu_disclosure
          expect(k.class).to eq Case::FOI::Standard
          expect(k.workflow).to eq "trigger"
          expect(k.current_state).to eq "drafting"
          expect(k.state_machine.permitted_events(approver.id)).to eq %i[add_message_to_case
                                                                         flag_for_clearance
                                                                         link_a_case
                                                                         reassign_user
                                                                         remove_linked_case
                                                                         unaccept_approver_assignment
                                                                         unflag_for_clearance]
        end
      end

      context "and pending_dacu_clearance state" do
        it "shows events" do
          k = create :pending_dacu_clearance_case, :flagged_accepted, :dacu_disclosure
          expect(k.class).to eq Case::FOI::Standard
          expect(k.workflow).to eq "trigger"
          expect(k.current_state).to eq "pending_dacu_clearance"
          expect(k.state_machine.permitted_events(approver.id)).to eq %i[add_message_to_case
                                                                         approve
                                                                         link_a_case
                                                                         reassign_user
                                                                         remove_linked_case
                                                                         unaccept_approver_assignment
                                                                         unflag_for_clearance
                                                                         upload_response_and_approve
                                                                         upload_response_and_return_for_redraft]
        end
      end

      context "and awaiting_dispatch" do
        it "shows events" do
          k = create :case_with_response, :flagged_accepted, :dacu_disclosure
          expect(k.class).to eq Case::FOI::Standard
          expect(k.workflow).to eq "trigger"
          expect(k.current_state).to eq "awaiting_dispatch"
          expect(k.state_machine.permitted_events(approver.id)).to eq %i[add_message_to_case
                                                                         link_a_case
                                                                         reassign_user
                                                                         remove_linked_case
                                                                         send_back]
        end
      end

      context "and responded" do
        it "shows events" do
          k = create :responded_case, :flagged_accepted, :dacu_disclosure
          expect(k.class).to eq Case::FOI::Standard
          expect(k.workflow).to eq "trigger"
          expect(k.current_state).to eq "responded"
          expect(k.state_machine.permitted_events(approver.id)).to eq %i[add_message_to_case
                                                                         link_a_case
                                                                         remove_linked_case]
        end
      end

      context "and closed" do
        it "shows events" do
          k = create :closed_case, :flagged_accepted, :dacu_disclosure
          expect(k.class).to eq Case::FOI::Standard
          expect(k.workflow).to eq "trigger"
          expect(k.current_state).to eq "closed"
          expect(k.state_machine.permitted_events(approver.id)).to eq %i[add_message_to_case
                                                                         link_a_case
                                                                         remove_linked_case]
        end
      end

      def approver_in_assigned_team(k)
        k.approver_assignments.first.user
      end

      def dacu_disclosure_approver(k)
        k.approver_assignments.for_team(BusinessUnit.dacu_disclosure).first.user
      end
    end
  end
end
