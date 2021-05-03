require 'rails_helper'

describe ConfigurableStateMachine::Machine do
  context 'flagged case' do
    context 'manager' do
      let(:manager) { find_or_create :disclosure_bmt_user }

      context 'unassigned state' do
        it 'should show permitted events' do
          k = create :overturned_ico_sar, :flagged, :dacu_disclosure
          expect(k.current_state).to eq 'unassigned'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :assign_responder,
                                                                      :destroy_case,
                                                                      :flag_for_clearance,
                                                                      :link_a_case,
                                                                      :remove_linked_case]
        end
      end

      context 'awaiting responder' do
        it 'should show permitted events' do
          k = create :awaiting_responder_ot_ico_sar, :flagged, :dacu_disclosure
          expect(k.current_state).to eq 'awaiting_responder'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :assign_to_new_team,
                                                                      :destroy_case,
                                                                      :flag_for_clearance,
                                                                      :link_a_case,
                                                                      :remove_linked_case]
        end
      end

      context 'drafting' do
        it 'should show permitted events' do
          k = create :accepted_ot_ico_sar, :flagged, :dacu_disclosure
          expect(k.current_state).to eq 'drafting'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :assign_to_new_team,
                                                                      :destroy_case,
                                                                      :extend_sar_deadline,
                                                                      :flag_for_clearance,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :unassign_from_user]
        end
      end

      context 'pending_dacu_clearance state' do
        it 'should show permitted events' do
          k = create :pending_dacu_clearance_ot_ico_sar
          expect(k.current_state).to eq 'pending_dacu_clearance'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :assign_to_new_team,
                                                                      :destroy_case,
                                                                      :extend_sar_deadline,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :unassign_from_user]
        end
      end

      context 'awaiting_dispatch state' do
        it 'should show permitted events' do
          k = create :awaiting_dispatch_ot_ico_sar, :flagged_accepted, :dacu_disclosure
          expect(k.current_state).to eq 'awaiting_dispatch'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :destroy_case,
                                                                      :extend_sar_deadline,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :unassign_from_user]
        end
      end

      context 'closed' do
        it "should show permitted events" do
          k = create :closed_ot_ico_sar, :flagged, :dacu_disclosure
          expect(k.current_state).to eq 'closed'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :assign_to_new_team,
                                                                      :destroy_case,
                                                                      :link_a_case,
                                                                      :remove_linked_case]
        end
      end
    end

    context 'responder' do
      context 'not in assigned team' do
        let(:responder) { find_or_create :foi_responder }

        context 'unassigned state' do
          it 'should show permitted events' do
            k = create :overturned_ico_sar, :flagged, :dacu_disclosure
            expect(k.current_state).to eq 'unassigned'
            expect(k.state_machine.permitted_events(responder.id)).to be_empty
          end
        end

        context 'awaiting responder state' do
          it 'should show permitted events' do
            k = create :awaiting_responder_ot_ico_sar, :flagged, :dacu_disclosure
            expect(k.current_state).to eq 'awaiting_responder'
            expect(k.state_machine.permitted_events(responder.id)).to be_empty
          end
        end

        context 'drafting state' do
          it 'should show permitted events' do
            k = create :accepted_ot_ico_sar, :flagged, :dacu_disclosure
            expect(k.current_state).to eq 'drafting'
            expect(k.state_machine.permitted_events(responder.id)).to be_empty
          end
        end

        context 'closed state' do
          it 'should show permitted events' do
            k = create :closed_ot_ico_sar, :flagged, :dacu_disclosure
            expect(k.current_state).to eq 'closed'
            expect(k.state_machine.permitted_events(responder.id)).to be_empty
          end
        end
      end



      context 'within assigned team' do

        context 'awaiting responder state' do
          it 'should show permitted events' do
            k = create :awaiting_responder_ot_ico_sar, :flagged, :dacu_disclosure
            responder = responder_in_assigned_team(k)
            expect(k.current_state).to eq 'awaiting_responder'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:accept_responder_assignment,
                                                                          :add_message_to_case,
                                                                          :reject_responder_assignment]
          end
        end

        context 'drafting state' do
          it 'should show permitted events' do
            k = create :accepted_ot_ico_sar, :flagged, :dacu_disclosure
            responder = responder_in_assigned_team(k)
            expect(k.current_state).to eq 'drafting'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                          :add_responses,
                                                                          :progress_for_clearance,
                                                                          :reassign_user, 
                                                                          :remove_response]
          end
        end

        context 'pending_dacu_clearance state' do
          it 'should show permitted events' do
            k = create :pending_dacu_clearance_ot_ico_sar
            responder = responder_in_assigned_team(k)
            expect(k.current_state).to eq 'pending_dacu_clearance'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                          :reassign_user]
          end
        end

        context 'awaiting_dispatch state' do
          it 'should show permitted events' do
            k = create :awaiting_dispatch_ot_ico_sar, :flagged_accepted, :dacu_disclosure
            responder = responder_in_assigned_team(k)
            expect(k.current_state).to eq 'awaiting_dispatch'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                          :close,
                                                                          :reassign_user,
                                                                          :respond,
                                                                          :respond_and_close]
          end
        end

        context 'closed state' do
          it 'should show permitted events' do
            k = create :closed_ot_ico_sar, :flagged, :dacu_disclosure
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
  end

  ##################### APPROVER FLAGGED ############################

  context 'approver' do
    context 'unassigned approver' do
      let(:unassigned_approver) { find_or_create :press_officer }

      context 'unassigned state' do
        it 'should show permitted events' do
          k = create :sar_case, :flagged

          expect(k.current_state).to eq 'unassigned'
          expect(k.workflow).to eq 'trigger'
          expect(k.state_machine.permitted_events(unassigned_approver.id))
            .to be_empty
        end
      end

      context 'awaiting responder state' do
        it 'shows events' do
          k = create :awaiting_responder_sar, :flagged

          expect(k.current_state).to eq 'awaiting_responder'
          expect(k.workflow).to eq 'trigger'
          expect(k.state_machine.permitted_events(unassigned_approver.id))
            .to be_empty
        end
      end

      context 'drafting state' do
        it 'shows events' do
          k = create :accepted_sar, :flagged

          expect(k.current_state).to eq 'drafting'
          expect(k.workflow).to eq 'trigger'
          expect(k.state_machine.permitted_events(unassigned_approver.id))
            .to be_empty
        end
      end

      context 'pending_dacu_clearance state' do
        it 'shows events' do
          k = create :pending_dacu_clearance_sar, :flagged

          expect(k.current_state).to eq 'pending_dacu_clearance'
          expect(k.workflow).to eq 'trigger'
          expect(k.state_machine.permitted_events(unassigned_approver.id))
            .to be_empty
        end
      end

      context 'awaiting_dispatch' do
        it 'shows events' do
          k = create :approved_sar, :flagged

          expect(k.current_state).to eq 'awaiting_dispatch'
          expect(k.workflow).to eq 'trigger'
          expect(k.state_machine.permitted_events(unassigned_approver.id))
            .to be_empty
        end
      end

      context 'closed' do
        it 'shows events' do
          k = create :closed_sar, :flagged

          expect(k.current_state).to eq 'closed'
          expect(k.workflow).to eq 'trigger'
          expect(k.state_machine.permitted_events(unassigned_approver.id))
            .to be_empty
        end
      end
    end

    context 'unaccepted approver' do
      let(:disclosure_specialist) { find_or_create :disclosure_specialist }

      context 'unassigned state' do
        it 'should show permitted events' do
          k = create :sar_case, :flagged

          expect(k.current_state).to eq 'unassigned'
          expect(k.workflow).to eq 'trigger'
          expect(k.state_machine.permitted_events(disclosure_specialist.id))
            .to match_array [:accept_approver_assignment, :unflag_for_clearance]
        end
      end

      context 'awaiting responder state' do
        it 'shows events' do
          k = create :awaiting_responder_sar, :flagged

          expect(k.current_state).to eq 'awaiting_responder'
          expect(k.workflow).to eq 'trigger'
          expect(k.state_machine.permitted_events(disclosure_specialist.id))
            .to match_array [:accept_approver_assignment, :unflag_for_clearance]
        end
      end

      context 'drafting state' do
        it 'shows events' do
          k = create :accepted_sar, :flagged

          expect(k.current_state).to eq 'drafting'
          expect(k.workflow).to eq 'trigger'
          expect(k.state_machine.permitted_events(disclosure_specialist.id))
            .to match_array [:accept_approver_assignment, :unflag_for_clearance]
        end
      end

      context 'pending_dacu_clearance state' do
        it 'shows events' do
          k = create :pending_dacu_clearance_sar, :flagged

          expect(k.current_state).to eq 'pending_dacu_clearance'
          expect(k.workflow).to eq 'trigger'
          expect(k.state_machine.permitted_events(disclosure_specialist.id))
            .to match_array [:accept_approver_assignment, :unflag_for_clearance]
        end
      end

      context 'awaiting_dispatch' do
        it 'shows events' do
          k = create :approved_sar, :flagged

          expect(k.current_state).to eq 'awaiting_dispatch'
          expect(k.workflow).to eq 'trigger'
          expect(k.state_machine.permitted_events(disclosure_specialist.id))
            .to be_empty
        end
      end

      context 'closed' do
        it 'shows events' do
          k = create :closed_sar, :flagged

          expect(k.current_state).to eq 'closed'
          expect(k.workflow).to eq 'trigger'
          expect(k.state_machine.permitted_events(disclosure_specialist.id))
            .to be_empty
        end
      end
    end

    context 'assigned approver' do
      context 'unassigned state' do

        it 'should show permitted events' do
          k = create :overturned_ico_sar, :flagged_accepted, :dacu_disclosure
          approver = approver_in_assigned_team(k)
          expect(k.current_state).to eq 'unassigned'
          expect(k.state_machine.permitted_events(approver.id)).to eq [ :add_message_to_case,
                                                                        :reassign_user,
                                                                        :unaccept_approver_assignment,
                                                                        :unflag_for_clearance]
        end
      end

      context 'awaiting responder state' do
        it 'shows events' do
          k = create :awaiting_responder_ot_ico_sar, :flagged_accepted, :dacu_disclosure
          approver = approver_in_assigned_team(k)
          expect(k.current_state).to eq 'awaiting_responder'
          expect(k.state_machine.permitted_events(approver.id)).to eq [ :add_message_to_case,
                                                                        :reassign_user,
                                                                        :unaccept_approver_assignment,
                                                                        :unflag_for_clearance]
        end
      end

      context 'drafting state' do
        it 'shows events' do
          k = create :accepted_ot_ico_sar, :flagged_accepted, :dacu_disclosure
          approver = approver_in_assigned_team(k)

          expect(k.current_state).to eq 'drafting'
          expect(k.state_machine.permitted_events(approver.id)).to eq [ :add_message_to_case,
                                                                        :extend_sar_deadline,
                                                                        :reassign_user,
                                                                        :unaccept_approver_assignment,
                                                                        :unflag_for_clearance]
        end
      end

      context 'pending_dacu_clearance state' do
        it 'shows events' do
          k = create :pending_dacu_clearance_ot_ico_sar, :flagged_accepted, :dacu_disclosure
          approver = approver_in_assigned_team(k)

          expect(k.current_state).to eq 'pending_dacu_clearance'
          expect(k.state_machine.permitted_events(approver.id)).to eq [:add_message_to_case,
                                                                       :approve,
                                                                       :extend_sar_deadline,
                                                                       :reassign_user,
                                                                       :request_amends,
                                                                       :unaccept_approver_assignment,
                                                                       :unflag_for_clearance]
        end
      end

      context 'awaiting_dispatch' do
        it 'shows events' do
          k = create :awaiting_dispatch_ot_ico_sar, :flagged_accepted, :dacu_disclosure
          approver = approver_in_assigned_team(k)
          expect(k.current_state).to eq 'awaiting_dispatch'
          expect(k.workflow).to eq 'trigger'
          expect(k.state_machine.permitted_events(approver.id)).to eq [ :add_message_to_case,
                                                                        :extend_sar_deadline,
                                                                        :reassign_user]
        end
      end

      context 'closed' do
        it 'shows events' do
          k = create :closed_ot_ico_sar, :flagged_accepted, :dacu_disclosure
          approver = approver_in_assigned_team(k)
          expect(k.current_state).to eq 'closed'
          expect(k.state_machine.permitted_events(approver.id)).to eq [ :add_message_to_case ]
        end
      end

      def approver_in_assigned_team(k)
        k.approver_assignments.first.user
      end
    end
  end
end
