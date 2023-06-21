require "rails_helper"

describe ConfigurableStateMachine::Machine do
  context "when flagged case" do
    context "and manager" do
      let(:manager) { find_or_create :disclosure_bmt_user }

      context "and unassigned state" do
        it "shows permitted events" do
          k = create :sar_internal_review, :flagged
          expect(k.current_state).to eq "unassigned"
          expect(k.state_machine.permitted_events(manager.id))
            .to eq %i[add_message_to_case
                      assign_responder
                      destroy_case
                      edit_case
                      flag_for_clearance
                      link_a_case
                      remove_linked_case]
        end
      end

      context "and awaiting responder" do
        it "shows permitted events" do
          k = create :awaiting_responder_sar_internal_review, :flagged_accepted
          expect(k.current_state).to eq "awaiting_responder"
          expect(k.state_machine.permitted_events(manager.id)).to eq %i[add_message_to_case
                                                                        assign_to_new_team
                                                                        destroy_case
                                                                        edit_case
                                                                        flag_for_clearance
                                                                        link_a_case
                                                                        remove_linked_case]
        end
      end

      context "and drafting" do
        it "shows permitted events" do
          k = create :accepted_sar_internal_review, :extended_deadline_sar_internal_review, :flagged_accepted
          expect(k.current_state).to eq "drafting"
          expect(k.state_machine.permitted_events(manager.id)).to eq %i[add_message_to_case
                                                                        assign_to_new_team
                                                                        destroy_case
                                                                        edit_case
                                                                        extend_sar_deadline
                                                                        flag_for_clearance
                                                                        link_a_case
                                                                        remove_linked_case
                                                                        remove_sar_deadline_extension
                                                                        unassign_from_user]
        end
      end

      context "and pending_dacu_clearance state" do
        it "shows permitted events" do
          k = create :pending_dacu_clearance_sar_internal_review, :flagged_accepted
          expect(k.current_state).to eq "pending_dacu_clearance"
          expect(k.state_machine.permitted_events(manager.id)).to eq %i[add_message_to_case
                                                                        assign_to_new_team
                                                                        destroy_case
                                                                        edit_case
                                                                        extend_sar_deadline
                                                                        link_a_case
                                                                        remove_linked_case
                                                                        unassign_from_user]
        end
      end

      context "and awaiting_dispatch state" do
        it "shows permitted events" do
          k = create :approved_sar_internal_review, :flagged_accepted
          expect(k.current_state).to eq "awaiting_dispatch"
          expect(k.state_machine.permitted_events(manager.id)).to eq %i[add_message_to_case
                                                                        destroy_case
                                                                        edit_case
                                                                        extend_sar_deadline
                                                                        link_a_case
                                                                        remove_linked_case
                                                                        unassign_from_user]
        end
      end

      context "and responded" do
        it "shows events - not member of case managing team" do
          non_team_manager = create :manager
          k = create :responded_sar_internal_review, :flagged, :dacu_disclosure

          expect(k.current_state).to eq "responded"
          expect(k.state_machine.permitted_events(non_team_manager.id))
          .to eq %i[add_message_to_case
                    close
                    destroy_case
                    edit_case
                    link_a_case
                    remove_linked_case
                    unassign_from_user]
        end

        it "shows events - member of case managing team" do
          k = create :responded_sar_internal_review, :flagged, :dacu_disclosure

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
        it "shows permitted events" do
          k = create :closed_sar_internal_review, :flagged_accepted
          expect(k.current_state).to eq "closed"
          expect(k.state_machine.permitted_events(manager.id)).to eq %i[add_message_to_case
                                                                        add_responses
                                                                        assign_to_new_team
                                                                        destroy_case
                                                                        edit_case
                                                                        link_a_case
                                                                        remove_linked_case
                                                                        remove_response
                                                                        update_closure]
        end
      end
    end

    context "and not in assigned team" do
      let(:responder) { create :responder }

      context "and unassigned state" do
        it "shows permitted events" do
          k = create :sar_internal_review, :flagged_accepted
          expect(k.current_state).to eq "unassigned"
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end

      context "and awaiting responder state" do
        it "shows permitted events" do
          k = create :awaiting_responder_sar_internal_review, :flagged_accepted
          expect(k.current_state).to eq "awaiting_responder"
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end

      context "and drafting state" do
        it "shows permitted events" do
          k = create :accepted_sar_internal_review, :flagged_accepted
          expect(k.current_state).to eq "drafting"
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end

      context "and pending_dacu_clearance state" do
        it "shows permitted events" do
          k = create :pending_dacu_clearance_sar_internal_review, :flagged_accepted
          expect(k.current_state).to eq "pending_dacu_clearance"
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end

      context "and awaiting_dispatch state" do
        it "shows permitted events" do
          k = create :approved_sar_internal_review, :flagged_accepted
          expect(k.current_state).to eq "awaiting_dispatch"
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end

      context "and closed state" do
        it "shows permitted events" do
          k = create :closed_sar_internal_review, :flagged_accepted
          expect(k.current_state).to eq "closed"
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end
    end

    context "and responder within assigned team" do
      context "and awaiting responder state" do
        it "shows permitted events" do
          k = create :awaiting_responder_sar_internal_review, :flagged_accepted
          responder = responder_in_assigned_team(k)
          expect(k.current_state).to eq "awaiting_responder"
          expect(k.state_machine.permitted_events(responder.id)).to eq %i[accept_responder_assignment
                                                                          add_message_to_case
                                                                          reject_responder_assignment]
        end
      end

      context "and drafting state" do
        it "shows permitted events" do
          k = create :accepted_sar_internal_review, :flagged_accepted
          responder = responder_in_assigned_team(k)
          expect(k.current_state).to eq "drafting"
          expect(k.state_machine.permitted_events(responder.id)).to eq %i[add_message_to_case
                                                                          progress_for_clearance
                                                                          reassign_user]
        end
      end

      context "and pending_dacu_clearance state" do
        it "shows permitted events" do
          k = create :pending_dacu_clearance_sar_internal_review, :flagged_accepted
          responder = responder_in_assigned_team(k)
          expect(k.current_state).to eq "pending_dacu_clearance"
          expect(k.state_machine.permitted_events(responder.id)).to eq %i[add_message_to_case
                                                                          reassign_user]
        end
      end

      context "and awaiting_dispatch state" do
        it "shows permitted events" do
          k = create :approved_sar_internal_review, :flagged_accepted
          responder = responder_in_assigned_team(k)
          expect(k.current_state).to eq "awaiting_dispatch"
          expect(k.state_machine.permitted_events(responder.id)).to eq %i[add_message_to_case
                                                                          reassign_user
                                                                          respond]
        end
      end

      context "and closed state" do
        it "shows permitted events" do
          k = create :closed_sar_internal_review, :flagged_accepted
          responder = responder_in_assigned_team(k)
          expect(k.current_state).to eq "closed"
          expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case]
        end
      end
    end

    def responder_in_assigned_team(kase)
      create :responder, responding_teams: [kase.responding_team]
    end

    context "and approver" do
      context "and unassigned approver" do
        let(:team_dacu_disclosure)  { find_or_create :team_dacu_disclosure }
        let(:unassigned_approver)   do
          create :approver,
                 approving_team: team_dacu_disclosure
        end

        context "and awaiting responder state" do
          it "shows events" do
            k = create :awaiting_responder_sar_internal_review, :flagged_accepted

            expect(k.current_state).to eq "awaiting_responder"
            expect(k.state_machine.permitted_events(unassigned_approver.id))
              .to match_array [:reassign_user]
          end
        end

        context "and drafting state" do
          it "shows events" do
            k = create :accepted_sar_internal_review, :flagged_accepted

            expect(k.current_state).to eq "drafting"
            expect(k.state_machine.permitted_events(unassigned_approver.id))
              .to match_array [:reassign_user]
          end
        end

        context "and pending_dacu_clearance state" do
          it "shows events" do
            k = create :pending_dacu_clearance_sar_internal_review, :flagged_accepted

            expect(k.current_state).to eq "pending_dacu_clearance"
            expect(k.state_machine.permitted_events(unassigned_approver.id))
              .to match_array [:reassign_user]
          end
        end

        context "and awaiting_dispatch" do
          it "shows events" do
            k = create :approved_sar_internal_review, :flagged_accepted

            expect(k.current_state).to eq "awaiting_dispatch"
            expect(k.workflow).to eq "trigger"
            expect(k.state_machine.permitted_events(unassigned_approver.id))
              .to match_array [:reassign_user]
          end
        end

        context "and closed" do
          it "shows events" do
            k = create :closed_sar_internal_review, :flagged_accepted

            expect(k.current_state).to eq "closed"
            expect(k.state_machine.permitted_events(unassigned_approver.id))
              .to be_empty
          end
        end
      end
    end

    ##################### APPROVER FLAGGED ############################

    context "and assigned approver" do
      let(:approver) { find_or_create :disclosure_specialist }

      context "and unassigned state" do
        it "shows permitted events" do
          k = create :sar_internal_review, :flagged_accepted
          expect(k.current_state).to eq "unassigned"
          expect(k.state_machine.permitted_events(approver.id))
            .to match_array %i[
              add_message_to_case
              reassign_user
              edit_case
              unaccept_approver_assignment
            ]
        end
      end

      context "and awaiting responder state" do
        it "shows events" do
          k = create :awaiting_responder_sar_internal_review, :flagged_accepted
          approver = approver_in_assigned_team(k)
          expect(k.current_state).to eq "awaiting_responder"
          expect(k.state_machine.permitted_events(approver.id))
            .to match_array %i[
              add_message_to_case
              reassign_user
              edit_case
              unaccept_approver_assignment
            ]
        end
      end

      context "and drafting state" do
        it "shows events" do
          k = create :accepted_sar_internal_review, :extended_deadline_sar_internal_review, :flagged_accepted
          approver = approver_in_assigned_team(k)

          expect(k.current_state).to eq "drafting"
          expect(k.state_machine.permitted_events(approver.id))
            .to eq %i[
              add_message_to_case
              edit_case
              extend_sar_deadline
              reassign_user
              remove_sar_deadline_extension
              unaccept_approver_assignment
            ]
        end
      end

      context "and pending_dacu_clearance state" do
        it "shows events" do
          k = create :pending_dacu_clearance_sar_internal_review, :flagged_accepted
          approver = approver_in_assigned_team(k)

          expect(k.current_state).to eq "pending_dacu_clearance"
          expect(k.state_machine.permitted_events(approver.id))
            .to eq %i[
              add_message_to_case
              approve
              edit_case
              extend_sar_deadline
              reassign_user
              request_amends
              unaccept_approver_assignment
            ]
        end
      end

      context "and awaiting_dispatch" do
        it "shows events" do
          k = create :approved_sar_internal_review, :flagged_accepted
          approver = approver_in_assigned_team(k)
          expect(k.current_state).to eq "awaiting_dispatch"
          expect(k.workflow).to eq "trigger"
          expect(k.state_machine.permitted_events(approver.id)).to eq %i[add_message_to_case
                                                                         edit_case
                                                                         extend_sar_deadline
                                                                         reassign_user]
        end
      end

      context "and closed" do
        it "shows events" do
          k = create :closed_sar_internal_review, :flagged_accepted
          approver = approver_in_assigned_team(k)
          expect(k.current_state).to eq "closed"
          expect(k.state_machine.permitted_events(approver.id)).to eq %i[add_message_to_case
                                                                         edit_case
                                                                         update_closure]
        end
      end

      def approver_in_assigned_team(kase)
        kase.approver_assignments.first.user
      end
    end
  end
end
