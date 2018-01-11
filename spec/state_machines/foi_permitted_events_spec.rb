require 'rails_helper'

describe 'FOI permittted events' do
  context 'non-flagged case' do
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
                                                                   :link_a_case]
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
                                                                      :link_a_case]
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
                                                                      :extend_for_pit,
                                                                      :flag_for_clearance,
                                                                      :link_a_case,
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
                                                                      :extend_for_pit,
                                                                      :flag_for_clearance,
                                                                      :link_a_case,
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
                                                                      :extend_for_pit,
                                                                      :link_a_case]
        end
      end

      context 'closed' do
        it 'shows events' do
          k = create :closed_case
          expect(k.current_state).to eq 'closed'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:destroy_case, :edit_case, :link_a_case]
        end
      end

    end





    context 'responder' do

      context 'responder not in team' do

        let(:responder)   { create :responder }

        context 'unassigned state' do
          it 'should show permitted events' do
            k = create :case
            expect(k.current_state).to eq 'unassigned'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case]
          end
        end

        context 'awaiting responder state' do
          it 'shows events' do
            k = create :awaiting_responder_case
            expect(k.current_state).to eq 'awaiting_responder'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:link_a_case]
          end
        end

        context 'awaiting_dispatch' do
          it 'shows events' do
            k = create :case_with_response
            expect(k.current_state).to eq 'awaiting_dispatch'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:extend_for_pit,
                                                                          :link_a_case,
                                                                          :request_further_clearance]
          end
        end

        context 'responded state' do
          it 'shows events' do
            k = create :responded_case
            expect(k.current_state).to eq 'responded'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:extend_for_pit, :link_a_case]
          end
        end
      end

      context 'responder in assigned team' do

        context 'awaiting_responder state' do
          it 'shows events' do
            k = create :awaiting_responder_case
            responder = responder_in_assigned_team(k)
            expect(k.current_state).to eq 'awaiting_responder'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:accept_responder_assignment,
                                                                          :add_message_to_case,
                                                                          :link_a_case,
                                                                          :reject_responder_assignment]

          end
        end

        context 'drafting state' do
          it 'shows events' do
            k = create :accepted_case
            responder = responder_in_assigned_team(k)
            expect(k.current_state).to eq 'drafting'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                          :add_responses,
                                                                          :extend_for_pit,
                                                                          :link_a_case,
                                                                          :reassign_user,
                                                                          :request_further_clearance]
          end
        end

        context 'awaiting_dispatch state' do
          it 'shows events' do
            k = create :case_with_response
            responder = responder_in_assigned_team(k)
            expect(k.current_state).to eq 'awaiting_dispatch'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                          :add_responses,
                                                                          :extend_for_pit,
                                                                          :link_a_case,
                                                                          :remove_last_response,
                                                                          :remove_response,
                                                                          :request_further_clearance,
                                                                          :respond]
          end
        end

        context 'resonded state' do
          it 'shows events' do
            k = create :responded_case
            responder = responder_in_assigned_team(k)
            expect(k.current_state).to eq 'responded'
            expect(k.state_machine.permitted_events(responder.id)).to eq [:extend_for_pit, :link_a_case]
          end
        end
      end

      def responder_in_assigned_team(k)
        create :responder, responding_teams: [k.responding_team]
      end
    end
  end
end
