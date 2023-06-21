require "rails_helper"

describe ConfigurableStateMachine::Machine do
  describe "standard workflow" do
    ##################### MANAGER  ############################

    context "when manager" do
      let(:manager) { create :manager }

      context "and unassigned state" do
        it "shows permitted events" do
          k = create :case
          expect(k.class).to eq Case::FOI::Standard
          expect(k.workflow).to eq "standard"
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
          k = create :awaiting_responder_case
          expect(k.class).to eq Case::FOI::Standard
          expect(k.workflow).to eq "standard"
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
          k = create :accepted_case
          expect(k.class).to eq Case::FOI::Standard
          expect(k.workflow).to eq "standard"
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

      context "and awaiting_dispatch" do
        it "shows events" do
          k = create :case_with_response
          expect(k.class).to eq Case::FOI::Standard
          expect(k.workflow).to eq "standard"
          expect(k.current_state).to eq "awaiting_dispatch"
          expect(k.state_machine.permitted_events(manager.id)).to eq %i[add_message_to_case
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

      context "and responded" do
        it "shows events" do
          k = create :responded_case
          expect(k.class).to eq Case::FOI::Standard
          expect(k.workflow).to eq "standard"
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
          k = create :closed_case
          expect(k.class).to eq Case::FOI::Standard
          expect(k.workflow).to eq "standard"
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

    ##################### RESPONDER ############################

    context "when responder" do
      context "and responder not in team" do
        let(:responder) { create :responder }

        context "and unassigned state" do
          it "shows permitted events" do
            k = create :case
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "standard"
            expect(k.current_state).to eq "unassigned"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[link_a_case remove_linked_case]
          end
        end

        context "and awaiting responder state" do
          it "shows events" do
            k = create :awaiting_responder_case
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "standard"
            expect(k.current_state).to eq "awaiting_responder"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[link_a_case remove_linked_case]
          end
        end

        context "and drafting state" do
          it "shows events" do
            k = create :accepted_case
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "standard"
            expect(k.current_state).to eq "drafting"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[link_a_case remove_linked_case]
          end
        end

        context "and awaiting_dispatch" do
          it "shows events" do
            k = create :case_with_response
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "standard"
            expect(k.current_state).to eq "awaiting_dispatch"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[link_a_case
                                                                            remove_linked_case]
          end
        end

        context "and responded state" do
          it "shows events" do
            k = create :responded_case
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "standard"
            expect(k.current_state).to eq "responded"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[link_a_case remove_linked_case]
          end
        end

        context "and closed state" do
          it "shows events" do
            k = create :closed_case
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "standard"
            expect(k.current_state).to eq "closed"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[add_message_to_case
                                                                            link_a_case
                                                                            remove_linked_case]
          end
        end
      end

      context "and responder in assigned team" do
        # Request further clearance is not permitted by the policies so has been removed
        # from state machine permitted events check
        context "and awaiting_responder state" do
          it "shows events" do
            k = create :awaiting_responder_case
            responder = responder_in_assigned_team(k)
            permitted_events = k.state_machine.permitted_events(responder.id) - [:request_further_clearance]
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "standard"
            expect(k.current_state).to eq "awaiting_responder"
            expect(permitted_events).to eq %i[accept_responder_assignment
                                              add_message_to_case
                                              link_a_case
                                              reject_responder_assignment
                                              remove_linked_case]
          end
        end

        context "and drafting state" do
          it "shows events" do
            k = create :accepted_case
            responder = responder_in_assigned_team(k)
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "standard"
            expect(k.current_state).to eq "drafting"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[add_message_to_case
                                                                            add_responses
                                                                            link_a_case
                                                                            reassign_user
                                                                            remove_linked_case
                                                                            remove_response]
          end
        end

        context "and awaiting_dispatch state" do
          it "shows events" do
            k = create :case_with_response
            responder = responder_in_assigned_team(k)
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "standard"
            expect(k.current_state).to eq "awaiting_dispatch"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[add_message_to_case
                                                                            add_responses
                                                                            link_a_case
                                                                            reassign_user
                                                                            remove_linked_case
                                                                            remove_response
                                                                            respond]
          end
        end

        context "and responded state" do
          it "shows events" do
            k = create :responded_case
            responder = responder_in_assigned_team(k)
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "standard"
            expect(k.current_state).to eq "responded"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[add_message_to_case
                                                                            link_a_case
                                                                            remove_linked_case]
          end
        end

        context "and closed state" do
          it "shows events" do
            k = create :closed_case
            responder = responder_in_assigned_team(k)
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "standard"
            expect(k.current_state).to eq "closed"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[add_message_to_case
                                                                            link_a_case
                                                                            remove_linked_case]
          end
        end
      end

      def responder_in_assigned_team(kase)
        create :responder, responding_teams: [kase.responding_team]
      end
    end

    ##################### APPROVER ############################

    context "when approver" do
      context "and unassigned approver" do
        let(:approver) { find_or_create :disclosure_specialist }

        context "and unassigned state" do
          it "shows permitted events" do
            k = create :case
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "standard"
            expect(k.current_state).to eq "unassigned"
            expect(k.state_machine.permitted_events(approver.id)).to eq %i[flag_for_clearance
                                                                           link_a_case
                                                                           remove_linked_case
                                                                           take_on_for_approval]
          end
        end

        context "and awaiting responder state" do
          it "shows events" do
            k = create :awaiting_responder_case
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "standard"
            expect(k.current_state).to eq "awaiting_responder"
            expect(k.state_machine.permitted_events(approver.id)).to eq %i[flag_for_clearance
                                                                           link_a_case
                                                                           remove_linked_case
                                                                           take_on_for_approval]
          end
        end

        context "and drafting state" do
          it "shows events" do
            k = create :accepted_case
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "standard"
            expect(k.current_state).to eq "drafting"
            expect(k.state_machine.permitted_events(approver.id)).to eq %i[flag_for_clearance
                                                                           link_a_case
                                                                           remove_linked_case
                                                                           take_on_for_approval]
          end
        end

        context "and awaiting_dispatch" do
          it "shows events" do
            k = create :case_with_response
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "standard"
            expect(k.current_state).to eq "awaiting_dispatch"
            expect(k.state_machine.permitted_events(approver.id)).to eq %i[link_a_case
                                                                           remove_linked_case
                                                                           take_on_for_approval]
          end
        end

        context "and responded" do
          it "shows events" do
            k = create :responded_case
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "standard"
            expect(k.current_state).to eq "responded"
            expect(k.state_machine.permitted_events(approver.id)).to eq %i[link_a_case
                                                                           remove_linked_case]
          end
        end

        context "and closed" do
          it "shows events" do
            k = create :closed_case
            expect(k.class).to eq Case::FOI::Standard
            expect(k.workflow).to eq "standard"
            expect(k.current_state).to eq "closed"
            expect(k.state_machine.permitted_events(approver.id)).to eq %i[add_message_to_case
                                                                           link_a_case
                                                                           remove_linked_case]
          end
        end
      end
    end
  end
end
