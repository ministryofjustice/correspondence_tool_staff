require 'rails_helper'

describe ConfigurableStateMachine::Machine do
  context 'flagged case' do
    context 'manager' do
      let(:manager) { create :manager }

      context 'unassigned state' do
        it 'should show permitted events' do
          k = create :sar_case, :flagged
          expect(k.current_state).to eq 'unassigned'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :assign_responder,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :flag_for_clearance,
                                                                      :link_a_case,
                                                                      :remove_linked_case]
        end
      end

      context 'awaiting responder' do
        it 'should show permitted events' do
          k = create :awaiting_responder_sar, :flagged_accepted
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

      context 'drafting' do
        it 'should show permitted events' do
          k = create :accepted_sar, :flagged_accepted
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

      context 'pending_dacu_clearance state' do
        it 'should show permitted events' do
          k = create :pending_dacu_clearance_sar, :flagged_accepted
          expect(k.current_state).to eq 'pending_dacu_clearance'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :assign_to_new_team,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :link_a_case,
                                                                      :remove_linked_case]
        end
      end

      context 'awaiting_dispatch state' do
        it 'should show permitted events' do
          k = create :approved_sar, :flagged_accepted
          expect(k.current_state).to eq 'awaiting_dispatch'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :link_a_case,
                                                                      :remove_linked_case]
        end
      end

      context 'closed' do
        it "should show permitted events" do
          k = create :closed_trigger_sar, :flagged_accepted
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

    context 'not in assigned team' do
      let(:responder) { create :responder }

      context 'unassigned state' do
        it 'should show permitted events' do
          k = create :sar_case, :flagged_accepted
          expect(k.current_state).to eq 'unassigned'
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end

      context 'awaiting responder state' do
        it 'should show permitted events' do
          k = create :awaiting_responder_sar, :flagged_accepted
          expect(k.current_state).to eq 'awaiting_responder'
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end

      context 'drafting state' do
        it 'should show permitted events' do
          k = create :accepted_sar, :flagged_accepted
          expect(k.current_state).to eq 'drafting'
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end

      context 'pending_dacu_clearance state' do
        it 'should show permitted events' do
          k = create :pending_dacu_clearance_sar, :flagged_accepted
          expect(k.current_state).to eq 'pending_dacu_clearance'
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end

      context 'awaiting_dispatch state' do
        it 'should show permitted events' do
          k = create :approved_sar, :flagged_accepted
          expect(k.current_state).to eq 'awaiting_dispatch'
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end

      context 'closed state' do
        it 'should show permitted events' do
          k = create :closed_trigger_sar, :flagged_accepted
          expect(k.current_state).to eq 'closed'
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end
    end



    context 'responder within assigned team' do

      context 'awaiting responder state' do
        it 'should show permitted events' do
          k = create :awaiting_responder_sar, :flagged_accepted
          responder = responder_in_assigned_team(k)
          expect(k.current_state).to eq 'awaiting_responder'
          expect(k.state_machine.permitted_events(responder.id)).to eq [:accept_responder_assignment,
                                                                        :add_message_to_case,
                                                                        :reject_responder_assignment]
        end
      end

      context 'drafting state' do
        it 'should show permitted events' do
          k = create :accepted_sar, :flagged_accepted
          responder = responder_in_assigned_team(k)
          expect(k.current_state).to eq 'drafting'
          expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                        :progress_for_clearance,
                                                                        :reassign_user]
        end
      end

      context 'pending_dacu_clearance state' do
        it 'should show permitted events' do
          k = create :pending_dacu_clearance_sar, :flagged_accepted
          responder = responder_in_assigned_team(k)
          expect(k.current_state).to eq 'pending_dacu_clearance'
          expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                        :reassign_user]
        end
      end

      context 'awaiting_dispatch state' do
        it 'should show permitted events' do
          k = create :approved_sar, :flagged_accepted
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
          k = create :closed_trigger_sar, :flagged_accepted
          responder = responder_in_assigned_team(k)
          expect(k.current_state).to eq 'closed'
          expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                        :update_closure]
        end
      end
    end

    def responder_in_assigned_team(k)
      create :responder, responding_teams: [k.responding_team]
    end

    context 'approver' do
      context 'unassigned approver' do
        let(:team_dacu_disclosure)      { find_or_create :team_dacu_disclosure }
        let(:disclosure_specialist)     { team_dacu_disclosure.users.first }
        let(:approver)                  { disclosure_specialist }

        context 'unassigned state' do
          it 'should show permitted events' do
            k = create :sar_case, :flagged_accepted

            expect(k.current_state).to eq 'unassigned'
            expect(k.state_machine.permitted_events(disclosure_specialist.id)).to be_empty
          end
        end

        context 'awaiting responder state' do
          it 'shows events' do
            k = create :awaiting_responder_sar, :flagged_accepted

            expect(k.current_state).to eq 'awaiting_responder'
            expect(k.state_machine.permitted_events(approver.id)).to be_empty
          end
        end

        context 'drafting state' do
          it 'shows events' do
            k = create :accepted_sar, :flagged_accepted

            expect(k.current_state).to eq 'drafting'
            expect(k.state_machine.permitted_events(approver.id)).to be_empty
          end
        end

        context 'pending_dacu_clearance state' do
          it 'shows events' do
            k = create :pending_dacu_clearance_sar, :flagged_accepted
            unassigned_approver = create :approver

            expect(k.current_state).to eq 'pending_dacu_clearance'
            expect(k.state_machine.permitted_events(unassigned_approver.id)).to be_empty
          end
        end

        context 'awaiting_dispatch' do
          it 'shows events' do
            k = create :approved_sar, :flagged_accepted

            expect(k.current_state).to eq 'awaiting_dispatch'
            expect(k.workflow).to eq 'trigger'
            expect(k.state_machine.permitted_events(approver.id)).to be_empty
          end
        end

        context 'closed' do
          it 'shows events' do
            k = create :closed_trigger_sar, :flagged_accepted

            expect(k.current_state).to eq 'closed'
            expect(k.state_machine.permitted_events(approver.id)).to be_empty
          end
        end
      end
    end


  ##################### APPROVER FLAGGED ############################

    context 'assigned approver' do
      context 'unassigned state' do

        it 'should show permitted events' do
          k = create :sar_case, :flagged_accepted
          approver = approver_in_assigned_team(k)
          expect(k.current_state).to eq 'unassigned'
          expect(k.state_machine.permitted_events(approver.id)).to eq [ :add_message_to_case,
                                                                        :reassign_user,
                                                                        :unaccept_approver_assignment]
        end
      end

      context 'awaiting responder state' do
        it 'shows events' do
          k = create :awaiting_responder_sar, :flagged_accepted
          approver = approver_in_assigned_team(k)
          expect(k.current_state).to eq 'awaiting_responder'
          expect(k.state_machine.permitted_events(approver.id)).to eq [ :add_message_to_case,
                                                                        :reassign_user,
                                                                        :unaccept_approver_assignment]
        end
      end

      context 'drafting state' do
        it 'shows events' do
          k = create :accepted_sar, :flagged_accepted
          approver = approver_in_assigned_team(k)

          expect(k.current_state).to eq 'drafting'
          expect(k.state_machine.permitted_events(approver.id)).to eq [ :add_message_to_case,
                                                                        :reassign_user,
                                                                        :unaccept_approver_assignment]
        end
      end

      context 'pending_dacu_clearance state' do
        it 'shows events' do
          k = create :pending_dacu_clearance_sar, :flagged_accepted
          approver = approver_in_assigned_team(k)

          expect(k.current_state).to eq 'pending_dacu_clearance'
          expect(k.state_machine.permitted_events(approver.id)).to eq [ :add_message_to_case,
                                                                        :approve,
                                                                        :reassign_user,
                                                                        :request_amends,
                                                                        :unaccept_approver_assignment]
        end
      end

      context 'awaiting_dispatch' do
        it 'shows events' do
          k = create :approved_sar, :flagged_accepted
          approver = approver_in_assigned_team(k)
          expect(k.current_state).to eq 'awaiting_dispatch'
          expect(k.workflow).to eq 'trigger'
          expect(k.state_machine.permitted_events(approver.id)).to eq [ :add_message_to_case,
                                                                        :reassign_user]
        end
      end

      context 'closed' do
        it 'shows events' do
          k = create :closed_trigger_sar, :flagged_accepted
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
