require 'rails_helper'

describe ConfigurableStateMachine::Machine do
  context 'trigger ico workflow' do

  ##################### MANAGER FLAGGED ############################

    context 'manager' do

      let(:manager)   { create :manager}

      context 'unassigned state' do
        it 'should show permitted events' do
          k = create :ico_foi_case, :flagged, :dacu_disclosure

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
          k = create :awaiting_responder_ico_foi_case, :flagged, :dacu_disclosure

          expect(k.current_state).to eq 'awaiting_responder'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :assign_to_new_team,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :link_a_case,
                                                                      :remove_linked_case]
        end
      end

      context 'drafting state' do
        it 'shows events' do
          k = create :accepted_ico_foi_case, :flagged, :dacu_disclosure

          expect(k.current_state).to eq 'drafting'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :assign_to_new_team,
                                                                      :destroy_case,
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
            k = create :ico_foi_case, :flagged, :dacu_disclosure

            expect(k.current_state).to eq 'unassigned'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case, :remove_linked_case]
          end
        end

        context 'awaiting responder state' do
          it 'shows events' do
            k = create :awaiting_responder_ico_foi_case, :flagged, :dacu_disclosure

            expect(k.current_state).to eq 'awaiting_responder'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case,:remove_linked_case]
          end
        end

        context 'drafting state' do
          it 'shows events' do
            k = create :accepted_ico_foi_case, :flagged, :dacu_disclosure

            expect(k.current_state).to eq 'drafting'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case,
                                                                          :remove_linked_case]
          end
        end
      end

      context 'responder in assigned team' do
        context 'awaiting_responder state' do
          it 'shows events' do
            k = create :awaiting_responder_ico_foi_case, :flagged, :dacu_disclosure
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
            k = create :accepted_ico_foi_case, :flagged, :dacu_disclosure
            responder = responder_in_assigned_team(k)

            expect(k.current_state).to eq 'drafting'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                          :add_response_to_flagged_case,
                                                                          :link_a_case,
                                                                          :reassign_user,
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
            k = create :ico_foi_case, :flagged, :dacu_disclosure

            expect(k.current_state).to eq 'unassigned'
            expect(k.state_machine.permitted_events(disclosure_specialist.id)).to eq [:accept_approver_assignment,
                                                                                      :link_a_case,
                                                                                      :reassign_user,
                                                                                      :remove_linked_case]
          end
        end

        context 'awaiting responder state' do
          it 'shows events' do
            k = create :awaiting_responder_ico_foi_case, :flagged, :dacu_disclosure

            expect(k.current_state).to eq 'awaiting_responder'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:accept_approver_assignment,
                                                                         :link_a_case,
                                                                         :reassign_user,
                                                                         :remove_linked_case]
          end
        end

        context 'drafting state' do
          it 'shows events' do
            k = create :accepted_ico_foi_case, :flagged, :dacu_disclosure

            expect(k.current_state).to eq 'drafting'
            expect(k.state_machine.permitted_events(approver.id)).to eq [ :accept_approver_assignment,
                                                                          :link_a_case,
                                                                          :reassign_user,
                                                                          :remove_linked_case]
          end
        end
      end


  ##################### APPROVER FLAGGED ############################

      context 'assigned approver' do
        context 'unassigned state' do

          it 'should show permitted events' do
            k = create :ico_foi_case, :flagged_accepted, :dacu_disclosure
            approver = approver_in_assigned_team(k)
            expect(k.current_state).to eq 'unassigned'
            expect(k.state_machine.permitted_events(approver.id)).to eq [ :add_message_to_case,
                                                                          :link_a_case,
                                                                          :reassign_user,
                                                                          :remove_linked_case,
                                                                          :unaccept_approver_assignment]
          end
        end

        context 'awaiting responder state' do
          it 'shows events' do
            k = create :awaiting_responder_ico_foi_case, :flagged_accepted, :dacu_disclosure
            approver = approver_in_assigned_team(k)
            expect(k.current_state).to eq 'awaiting_responder'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:add_message_to_case,
                                                                         :link_a_case,
                                                                         :reassign_user,
                                                                         :remove_linked_case,
                                                                         :unaccept_approver_assignment]
          end
        end

        context 'drafting state' do
          it 'shows events' do
            k = create :accepted_ico_foi_case, :flagged_accepted, :dacu_disclosure
            approver = approver_in_assigned_team(k)

            expect(k.current_state).to eq 'drafting'
            expect(k.state_machine.permitted_events(approver.id)).to eq [:add_message_to_case,
                                                                         :link_a_case,
                                                                         :reassign_user,
                                                                         :remove_linked_case,
                                                                         :unaccept_approver_assignment]
          end
        end
      end

      def approver_in_assigned_team(k)
        k.approver_assignments.first.user
      end
    end
  end
end
