require "rails_helper"

describe ConfigurableStateMachine::Machine do # rubocop:disable RSpec/FilePath
  describe "flagged case" do
    context "when manager" do
      let(:manager) { find_or_create :disclosure_bmt_user }

      context "when unassigned state" do
        it "shows permitted events" do
          k = create :sar_case, :flagged
          expect(k.current_state).to eq "unassigned"
          expect(k.state_machine.permitted_events(manager.id))
            .to eq %i[add_message_to_case
                      assign_responder
                      destroy_case
                      edit_case
                      flag_for_clearance
                      link_a_case
                      remove_linked_case
                      stop_the_clock]
        end
      end

      context "when awaiting responder" do
        it "shows permitted events" do
          k = create :awaiting_responder_sar, :flagged_accepted
          expect(k.current_state).to eq "awaiting_responder"
          expect(k.state_machine.permitted_events(manager.id)).to eq %i[add_message_to_case
                                                                        assign_to_new_team
                                                                        destroy_case
                                                                        edit_case
                                                                        flag_for_clearance
                                                                        link_a_case
                                                                        remove_linked_case
                                                                        stop_the_clock]
        end
      end

      context "when drafting" do
        it "shows permitted events" do
          k = create :accepted_sar, :extended_deadline_sar, :flagged_accepted
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
                                                                        stop_the_clock
                                                                        unassign_from_user]
        end
      end

      context "when pending_dacu_clearance state" do
        it "shows permitted events" do
          k = create :pending_dacu_clearance_sar, :flagged_accepted
          expect(k.current_state).to eq "pending_dacu_clearance"
          expect(k.state_machine.permitted_events(manager.id)).to eq %i[add_message_to_case
                                                                        assign_to_new_team
                                                                        destroy_case
                                                                        edit_case
                                                                        extend_sar_deadline
                                                                        link_a_case
                                                                        remove_linked_case
                                                                        stop_the_clock
                                                                        unassign_from_user]
        end
      end

      context "when awaiting_dispatch state" do
        it "shows permitted events" do
          k = create :approved_sar, :flagged_accepted
          expect(k.current_state).to eq "awaiting_dispatch"
          expect(k.state_machine.permitted_events(manager.id)).to eq %i[add_message_to_case
                                                                        destroy_case
                                                                        edit_case
                                                                        extend_sar_deadline
                                                                        link_a_case
                                                                        remove_linked_case
                                                                        stop_the_clock
                                                                        unassign_from_user]
        end
      end

      context "when closed" do
        it "shows permitted events" do
          k = create :closed_sar, :flagged_accepted
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

    context "when not in assigned team" do
      let(:responder) { create :responder }

      context "when unassigned state" do
        it "shows permitted events" do
          k = create :sar_case, :flagged_accepted
          expect(k.current_state).to eq "unassigned"
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end

      context "when awaiting responder state" do
        it "shows permitted events" do
          k = create :awaiting_responder_sar, :flagged_accepted
          expect(k.current_state).to eq "awaiting_responder"
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end

      context "when drafting state" do
        it "shows permitted events" do
          k = create :accepted_sar, :flagged_accepted
          expect(k.current_state).to eq "drafting"
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end

      context "when pending_dacu_clearance state" do
        it "shows permitted events" do
          k = create :pending_dacu_clearance_sar, :flagged_accepted
          expect(k.current_state).to eq "pending_dacu_clearance"
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end

      context "when awaiting_dispatch state" do
        it "shows permitted events" do
          k = create :approved_sar, :flagged_accepted
          expect(k.current_state).to eq "awaiting_dispatch"
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end

      context "when closed state" do
        it "shows permitted events" do
          k = create :closed_sar, :flagged_accepted
          expect(k.current_state).to eq "closed"
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end
    end

    context "when responder within assigned team" do
      context "and awaiting responder state" do
        it "shows permitted events" do
          k = create :awaiting_responder_sar, :flagged_accepted
          responder = responder_in_assigned_team(k)
          expect(k.current_state).to eq "awaiting_responder"
          expect(k.state_machine.permitted_events(responder.id)).to eq %i[accept_responder_assignment
                                                                          add_message_to_case
                                                                          reject_responder_assignment]
        end
      end

      context "when drafting state" do
        it "shows permitted events" do
          k = create :accepted_sar, :flagged_accepted
          responder = responder_in_assigned_team(k)
          expect(k.current_state).to eq "drafting"
          expect(k.state_machine.permitted_events(responder.id)).to eq %i[add_message_to_case
                                                                          progress_for_clearance
                                                                          reassign_user]
        end
      end

      context "when pending_dacu_clearance state" do
        it "shows permitted events" do
          k = create :pending_dacu_clearance_sar, :flagged_accepted
          responder = responder_in_assigned_team(k)
          expect(k.current_state).to eq "pending_dacu_clearance"
          expect(k.state_machine.permitted_events(responder.id)).to eq %i[add_message_to_case
                                                                          reassign_user]
        end
      end

      context "when awaiting_dispatch state" do
        it "shows permitted events" do
          k = create :approved_sar, :flagged_accepted
          responder = responder_in_assigned_team(k)
          expect(k.current_state).to eq "awaiting_dispatch"
          expect(k.state_machine.permitted_events(responder.id)).to eq %i[add_message_to_case
                                                                          close
                                                                          reassign_user
                                                                          respond
                                                                          respond_and_close]
        end
      end

      context "when closed state" do
        it "shows permitted events" do
          k = create :closed_sar, :flagged_accepted
          responder = responder_in_assigned_team(k)
          expect(k.current_state).to eq "closed"
          expect(k.state_machine.permitted_events(responder.id)).to eq %i[add_message_to_case
                                                                          update_closure]
        end
      end
    end

    def responder_in_assigned_team(kase)
      create :responder, responding_teams: [kase.responding_team]
    end

    describe "approver" do
      context "when unassigned approver" do
        let(:team_dacu_disclosure)  { find_or_create :team_dacu_disclosure }
        let(:unassigned_approver)   do
          create :approver,
                 approving_team: team_dacu_disclosure
        end

        context "when awaiting responder state" do
          it "shows events" do
            k = create :awaiting_responder_sar, :flagged_accepted

            expect(k.current_state).to eq "awaiting_responder"
            expect(k.state_machine.permitted_events(unassigned_approver.id))
              .to match_array %i[reassign_user stop_the_clock unflag_for_clearance]
          end
        end

        context "when drafting state" do
          it "shows events" do
            k = create :accepted_sar, :flagged_accepted

            expect(k.current_state).to eq "drafting"
            expect(k.state_machine.permitted_events(unassigned_approver.id))
              .to match_array %i[reassign_user stop_the_clock unflag_for_clearance]
          end
        end

        context "when pending_dacu_clearance state" do
          it "shows events" do
            k = create :pending_dacu_clearance_sar, :flagged_accepted

            expect(k.current_state).to eq "pending_dacu_clearance"
            expect(k.state_machine.permitted_events(unassigned_approver.id))
              .to match_array %i[reassign_user stop_the_clock unflag_for_clearance]
          end
        end

        context "when awaiting_dispatch" do
          it "shows events" do
            k = create :approved_sar, :flagged_accepted

            expect(k.current_state).to eq "awaiting_dispatch"
            expect(k.workflow).to eq "trigger"
            expect(k.state_machine.permitted_events(unassigned_approver.id))
              .to match_array %i[reassign_user stop_the_clock]
          end
        end

        context "when closed" do
          it "shows events" do
            k = create :closed_sar, :flagged_accepted

            expect(k.current_state).to eq "closed"
            expect(k.state_machine.permitted_events(unassigned_approver.id))
              .to be_empty
          end
        end
      end
    end

    ##################### APPROVER FLAGGED ############################

    context "when assigned approver" do
      let(:approver) { find_or_create :disclosure_specialist }

      context "when unassigned state" do
        it "shows permitted events" do
          k = create :sar_case, :flagged_accepted
          expect(k.current_state).to eq "unassigned"
          expect(k.state_machine.permitted_events(approver.id))
            .to match_array %i[
              add_message_to_case
              reassign_user
              stop_the_clock
              unaccept_approver_assignment
              unflag_for_clearance
            ]
        end
      end

      context "when awaiting responder state" do
        it "shows events" do
          k = create :awaiting_responder_sar, :flagged_accepted
          approver = approver_in_assigned_team(k)
          expect(k.current_state).to eq "awaiting_responder"
          expect(k.state_machine.permitted_events(approver.id))
            .to match_array %i[
              add_message_to_case
              reassign_user
              stop_the_clock
              unaccept_approver_assignment
              unflag_for_clearance
            ]
        end
      end

      context "when drafting state" do
        it "shows events" do
          k = create :accepted_sar, :extended_deadline_sar, :flagged_accepted
          approver = approver_in_assigned_team(k)

          expect(k.current_state).to eq "drafting"
          expect(k.state_machine.permitted_events(approver.id))
            .to eq %i[
              add_message_to_case
              extend_sar_deadline
              reassign_user
              remove_sar_deadline_extension
              stop_the_clock
              unaccept_approver_assignment
              unflag_for_clearance
            ]
        end
      end

      context "when pending_dacu_clearance state" do
        it "shows events" do
          k = create :pending_dacu_clearance_sar, :flagged_accepted
          approver = approver_in_assigned_team(k)

          expect(k.current_state).to eq "pending_dacu_clearance"
          expect(k.state_machine.permitted_events(approver.id))
            .to eq %i[
              add_message_to_case
              approve
              extend_sar_deadline
              reassign_user
              request_amends
              stop_the_clock
              unaccept_approver_assignment
              unflag_for_clearance
            ]
        end
      end

      context "when awaiting_dispatch" do
        it "shows events" do
          k = create :approved_sar, :flagged_accepted
          approver = approver_in_assigned_team(k)
          expect(k.current_state).to eq "awaiting_dispatch"
          expect(k.workflow).to eq "trigger"
          expect(k.state_machine.permitted_events(approver.id)).to eq %i[add_message_to_case
                                                                         extend_sar_deadline
                                                                         reassign_user
                                                                         stop_the_clock]
        end
      end

      context "when closed" do
        it "shows events" do
          k = create :closed_sar, :flagged_accepted
          approver = approver_in_assigned_team(k)
          expect(k.current_state).to eq "closed"
          expect(k.state_machine.permitted_events(approver.id)).to eq [:add_message_to_case]
        end
      end

      def approver_in_assigned_team(kase)
        kase.approver_assignments.first.user
      end
    end
  end
end
