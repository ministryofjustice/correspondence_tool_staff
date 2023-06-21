require "rails_helper"

describe ConfigurableStateMachine::Machine do
  describe "trigger ico workflow" do
    ##################### MANAGER FLAGGED ############################

    context "when manager" do
      let(:manager) { create :manager }

      context "and unassigned state" do
        it "shows permitted events" do
          k = create :ico_foi_case, :dacu_disclosure

          expect(k.current_state).to eq "unassigned"
          expect(k.state_machine.permitted_events(manager)).to eq %i[add_message_to_case
                                                                     assign_responder
                                                                     destroy_case
                                                                     edit_case
                                                                     flag_for_clearance
                                                                     link_a_case
                                                                     remove_linked_case]
        end
      end

      context "and awaiting responder state" do
        it "shows events" do
          k = create :awaiting_responder_ico_foi_case, :dacu_disclosure

          expect(k.current_state).to eq "awaiting_responder"
          expect(k.state_machine.permitted_events(manager.id)).to eq %i[add_message_to_case
                                                                        assign_to_new_team
                                                                        destroy_case
                                                                        edit_case
                                                                        link_a_case
                                                                        remove_linked_case]
        end
      end

      context "and drafting state" do
        it "shows events" do
          k = create :accepted_ico_foi_case, :dacu_disclosure

          expect(k.current_state).to eq "drafting"
          expect(k.state_machine.permitted_events(manager.id)).to eq %i[add_message_to_case
                                                                        assign_to_new_team
                                                                        destroy_case
                                                                        edit_case
                                                                        link_a_case
                                                                        remove_linked_case
                                                                        unassign_from_user]
        end
      end

      context "and pending_dacu_disclosure_clearance state" do
        it "shows events" do
          k = create :pending_dacu_clearance_ico_foi_case, :dacu_disclosure

          expect(k.current_state).to eq "pending_dacu_clearance"
          expect(k.state_machine.permitted_events(manager.id)).to eq %i[add_message_to_case
                                                                        destroy_case
                                                                        edit_case
                                                                        link_a_case
                                                                        remove_linked_case
                                                                        remove_response
                                                                        unassign_from_user]
        end
      end

      context "and awaiting_dispatch state" do
        it "shows events" do
          k = create :approved_ico_foi_case, :dacu_disclosure

          expect(k.current_state).to eq "awaiting_dispatch"
          expect(k.state_machine.permitted_events(manager.id)).to eq %i[add_message_to_case
                                                                        destroy_case
                                                                        edit_case
                                                                        link_a_case
                                                                        remove_linked_case
                                                                        remove_response
                                                                        unassign_from_user]
        end
      end

      context "and responded state" do
        it "shows events" do
          k = create :responded_ico_foi_case, :dacu_disclosure
          manager_in_the_case = k.managing_team.users.first

          expect(k.current_state).to eq "responded"
          expect(k.state_machine.permitted_events(manager_in_the_case.id)).to eq %i[
            add_message_to_case
            close
            destroy_case
            edit_case
            link_a_case
            record_further_action
            remove_linked_case
            remove_response
            require_further_action
            require_further_action_to_responder_team
            require_further_action_unassigned
            unassign_from_user
          ]
        end
      end

      context "and closed state" do
        it "shows events" do
          k = create :closed_ico_foi_case, :dacu_disclosure

          expect(k.current_state).to eq "closed"
          expect(k.state_machine.permitted_events(manager.id)).to eq %i[add_message_to_case
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

    ##################### RESPONDER FLAGGED ############################

    context "when responder" do
      context "and responder not in team" do
        let(:responder) { create :responder }

        context "and unassigned state" do
          it "shows permitted events" do
            k = create :ico_foi_case, :dacu_disclosure

            expect(k.current_state).to eq "unassigned"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[link_a_case remove_linked_case]
          end
        end

        context "and awaiting responder state" do
          it "shows events" do
            k = create :awaiting_responder_ico_foi_case, :dacu_disclosure

            expect(k.current_state).to eq "awaiting_responder"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[link_a_case remove_linked_case]
          end
        end

        context "and drafting state" do
          it "shows events" do
            k = create :accepted_ico_foi_case, :dacu_disclosure

            expect(k.current_state).to eq "drafting"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[link_a_case
                                                                            remove_linked_case]
          end
        end

        context "and pending_dacu_clearance state" do
          it "shows events" do
            k = create :pending_dacu_clearance_ico_foi_case, :dacu_disclosure

            expect(k.current_state).to eq "pending_dacu_clearance"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[link_a_case
                                                                            remove_linked_case]
          end
        end

        context "and awaiting_dispatch state" do
          it "shows events" do
            k = create :approved_ico_foi_case, :dacu_disclosure

            expect(k.current_state).to eq "awaiting_dispatch"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[link_a_case
                                                                            remove_linked_case]
          end
        end

        context "and responded state" do
          it "shows events" do
            k = create :responded_ico_foi_case, :dacu_disclosure

            expect(k.current_state).to eq "responded"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[link_a_case
                                                                            remove_linked_case]
          end
        end

        context "and closed state" do
          it "shows events" do
            k = create :closed_ico_foi_case, :dacu_disclosure

            expect(k.current_state).to eq "closed"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[link_a_case
                                                                            remove_linked_case]
          end
        end
      end

      context "and responder in assigned team" do
        context "and awaiting_responder state" do
          it "shows events" do
            k = create :awaiting_responder_ico_foi_case, :dacu_disclosure
            responder = responder_in_assigned_team(k)

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
            k = create :accepted_ico_foi_case, :dacu_disclosure
            responder = responder_in_assigned_team(k)

            expect(k.current_state).to eq "drafting"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[add_message_to_case
                                                                            add_responses
                                                                            link_a_case
                                                                            reassign_user
                                                                            remove_linked_case]
          end
        end

        context "and pending_dacu_disclosure_clearance state" do
          it "shows events" do
            k = create :pending_dacu_clearance_ico_foi_case, :dacu_disclosure
            responder = responder_in_assigned_team(k)

            expect(k.current_state).to eq "pending_dacu_clearance"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[add_message_to_case
                                                                            link_a_case
                                                                            reassign_user
                                                                            remove_linked_case]
          end
        end

        context "and awaiting_dispatch state" do
          it "shows events" do
            k = create :approved_ico_foi_case, :dacu_disclosure
            responder = responder_in_assigned_team(k)

            expect(k.current_state).to eq "awaiting_dispatch"
            expect(k.state_machine.permitted_events(responder.id)).to eq %i[add_message_to_case
                                                                            add_responses
                                                                            link_a_case
                                                                            reassign_user
                                                                            remove_linked_case
                                                                            remove_response]
            # :respond
          end
        end

        context "and responded state" do
          it "shows events" do
            k = create :responded_ico_foi_case, :dacu_disclosure
            responder = responder_in_assigned_team(k)

            expect(k.current_state).to eq "responded"
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                          :link_a_case,
                                                                          # :reassign_user,
                                                                          :remove_linked_case]
          end
        end

        context "and closed state" do
          it "shows events" do
            k = create :closed_ico_foi_case, :dacu_disclosure
            responder = responder_in_assigned_team(k)

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

    ##################### APPROVER FLAGGED ############################

    context "when approver" do
      context "and approver in assigned team" do
        let(:team_dacu_disclosure)      { find_or_create :team_dacu_disclosure }
        let(:disclosure_specialist)     { team_dacu_disclosure.users.first }
        let(:approver)                  { disclosure_specialist }

        context "and unassigned state" do
          it "shows permitted events" do
            k = create :ico_foi_case

            expect(k.current_state).to eq "unassigned"
            expect(k.state_machine.permitted_events(disclosure_specialist.id))
              .to eq %i[accept_approver_assignment
                        add_message_to_case
                        link_a_case
                        reassign_user
                        remove_linked_case]
          end
        end

        context "and awaiting responder state" do
          it "shows events" do
            k = create :awaiting_responder_ico_foi_case, :dacu_disclosure

            expect(k.current_state).to eq "awaiting_responder"
            expect(k.state_machine.permitted_events(approver.id)).to eq %i[accept_approver_assignment
                                                                           add_message_to_case
                                                                           link_a_case
                                                                           reassign_user
                                                                           remove_linked_case]
          end
        end

        context "and drafting state" do
          it "shows events" do
            k = create :accepted_ico_foi_case, :dacu_disclosure

            expect(k.current_state).to eq "drafting"
            expect(k.state_machine.permitted_events(approver.id))
              .to eq %i[accept_approver_assignment
                        add_message_to_case
                        link_a_case
                        reassign_user
                        remove_linked_case]
          end
        end

        context "and drafting state and approver-accepted" do
          it "shows events" do
            k = create(:accepted_ico_foi_case,
                       :flagged_accepted,
                       :dacu_disclosure,
                       approver:)

            expect(k.current_state).to eq "drafting"
            expect(k.state_machine.permitted_events(approver.id))
              .to eq %i[add_message_to_case
                        link_a_case
                        reassign_user
                        remove_linked_case
                        unaccept_approver_assignment]
          end
        end

        context "and pending_dacu_disclosure_clearance state" do
          it "shows events" do
            k = create(:pending_dacu_clearance_ico_foi_case,
                       :dacu_disclosure,
                       approver:)

            expect(k.current_state).to eq "pending_dacu_clearance"
            expect(k.state_machine.permitted_events(approver.id))
              .to eq %i[add_message_to_case
                        approve
                        link_a_case
                        reassign_user
                        remove_linked_case
                        unaccept_approver_assignment
                        upload_response_and_approve
                        upload_response_and_return_for_redraft]
          end
        end

        context "and awaiting_dispatch state" do
          it "shows events" do
            k = create(:approved_ico_foi_case,
                       :dacu_disclosure,
                       approver:)

            expect(k.current_state).to eq "awaiting_dispatch"
            expect(k.state_machine.permitted_events(approver.id)).to eq %i[add_message_to_case
                                                                           link_a_case
                                                                           reassign_user
                                                                           remove_linked_case
                                                                           respond]
          end
        end

        context "and responded state" do
          it "shows events" do
            k = create(:responded_ico_foi_case,
                       :dacu_disclosure,
                       approver:)

            expect(k.current_state).to eq "responded"
            expect(k.state_machine.permitted_events(approver.id)).to eq %i[add_message_to_case
                                                                           link_a_case
                                                                           remove_linked_case]
          end
        end

        context "and closed state" do
          it "shows events" do
            k = create :closed_ico_foi_case, :dacu_disclosure

            expect(k.current_state).to eq "closed"
            expect(k.state_machine.permitted_events(approver.id)).to eq %i[add_message_to_case
                                                                           link_a_case
                                                                           remove_linked_case]
          end
        end
      end

      ##################### APPROVER FLAGGED ############################

      context "and assigned approver" do
        context "and unassigned state" do
          it "shows permitted events" do
            k = create :ico_foi_case, :flagged_accepted, :dacu_disclosure
            approver = approver_in_assigned_team(k)
            expect(k.current_state).to eq "unassigned"
            expect(k.state_machine.permitted_events(approver.id)).to eq %i[add_message_to_case
                                                                           link_a_case
                                                                           reassign_user
                                                                           remove_linked_case
                                                                           unaccept_approver_assignment]
          end
        end

        context "and awaiting responder state" do
          it "shows events" do
            k = create :awaiting_responder_ico_foi_case, :flagged_accepted, :dacu_disclosure
            approver = approver_in_assigned_team(k)
            expect(k.current_state).to eq "awaiting_responder"
            expect(k.state_machine.permitted_events(approver.id)).to eq %i[add_message_to_case
                                                                           link_a_case
                                                                           reassign_user
                                                                           remove_linked_case
                                                                           unaccept_approver_assignment]
          end
        end

        context "and drafting state" do
          it "shows events" do
            k = create :accepted_ico_foi_case, :flagged_accepted, :dacu_disclosure
            approver = approver_in_assigned_team(k)
            expect(k.current_state).to eq "drafting"
            expect(k.state_machine.permitted_events(approver.id)).to eq %i[add_message_to_case
                                                                           link_a_case
                                                                           reassign_user
                                                                           remove_linked_case
                                                                           unaccept_approver_assignment]
          end
        end

        context "and pending_dacu_disclosure_clearance state" do
          it "shows events" do
            k = create :pending_dacu_clearance_ico_foi_case, :flagged_accepted, :dacu_disclosure
            approver = approver_in_assigned_team(k)

            expect(k.current_state).to eq "pending_dacu_clearance"
            expect(k.state_machine.permitted_events(approver.id)).to eq %i[add_message_to_case
                                                                           approve
                                                                           link_a_case
                                                                           reassign_user
                                                                           remove_linked_case
                                                                           unaccept_approver_assignment
                                                                           upload_response_and_approve
                                                                           upload_response_and_return_for_redraft]
          end
        end

        context "and awaiting_dispatch state" do
          it "shows events" do
            k = create :approved_ico_foi_case, :flagged_accepted, :dacu_disclosure
            approver = approver_in_assigned_team(k)

            expect(k.current_state).to eq "awaiting_dispatch"
            expect(k.state_machine.permitted_events(approver.id)).to eq %i[add_message_to_case
                                                                           link_a_case
                                                                           reassign_user
                                                                           remove_linked_case
                                                                           respond]
          end
        end

        context "and responded state" do
          it "shows events" do
            k = create :responded_ico_foi_case, :flagged_accepted, :dacu_disclosure
            approver = approver_in_assigned_team(k)

            expect(k.current_state).to eq "responded"
            expect(k.state_machine.permitted_events(approver.id)).to eq [:add_message_to_case,
                                                                         :link_a_case,
                                                                         # :reassign_user,
                                                                         :remove_linked_case]
          end
        end

        context "and when closed state" do
          it "shows events" do
            k = create :closed_ico_foi_case, :flagged_accepted, :dacu_disclosure
            approver = approver_in_assigned_team(k)

            expect(k.current_state).to eq "closed"
            expect(k.state_machine.permitted_events(approver.id)).to eq %i[add_message_to_case
                                                                           link_a_case
                                                                           remove_linked_case]
          end
        end
      end

      def approver_in_assigned_team(kase)
        kase.approver_assignments.first.user
      end
    end
  end
end
