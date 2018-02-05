require 'rails_helper'

describe ConfigurableStateMachine::Machine do
  context 'non-flagged case' do
    context 'manager' do
      let(:manager) { create :manager }

      context 'unassigned state' do
        it 'should show permitted events' do
          k = create :sar_case
          expect(k.current_state).to eq 'unassigned'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :assign_responder,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :link_a_case]
        end
      end

      context 'awaiting responder' do
        it 'should show permitted events' do
          k = create :awaiting_responder_sar
          expect(k.current_state).to eq 'awaiting_responder'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :assign_to_new_team,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :flag_for_clearance,
                                                                      :link_a_case]
        end
      end

      context 'drafting' do
        it 'should show permitted events' do
          k = create :accepted_sar
          expect(k.current_state).to eq 'drafting'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :assign_to_new_team,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :link_a_case]
        end
      end

      context "awaiting dispatch" do
        it "should show permitted events" do
          k = create :sar_with_response
          expect(k.current_state).to eq 'awaiting_dispatch'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :link_a_case]
        end
      end

      context 'responded' do
        it "should show permitted events" do
          k = create :responded_sar
          expect(k.current_state).to eq 'responded'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      # :close,
                                                                      :destroy_case,
                                                                      :edit_case,
                                                                      :link_a_case]
        end
      end
      context 'closed' do
        it "should show permitted events" do
          k = create :closed_sar, :clarification_required
          expect(k.current_state).to eq 'closed'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:destroy_case,
                                                                      :edit_case,
                                                                      :link_a_case]
        end
      end
    end

    context 'not in assigned team' do
      let(:responder) { create :responder }

      context 'unassigned state' do
        it 'should show permitted events' do
          k = create :sar_case
          expect(k.current_state).to eq 'unassigned'
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end

      context 'awaiting responder state' do
        it 'should show permitted events' do
          k = create :awaiting_responder_sar
          expect(k.current_state).to eq 'awaiting_responder'
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end

      context 'drafting state' do
        it 'should show permitted events' do
          k = create :accepted_sar
          expect(k.current_state).to eq 'drafting'
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end

      context 'awaiting dispatch state' do
        it 'should show permitted events' do
          k = create :sar_with_response
          expect(k.current_state).to eq 'awaiting_dispatch'
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end

      context 'responded state' do
        it 'should show permitted events' do
          k = create :responded_sar
          expect(k.current_state).to eq 'responded'
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end

      context 'closed state' do
        it 'should show permitted events' do
          k = create :closed_sar, :clarification_required
          expect(k.current_state).to eq 'closed'
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end
    end



    context 'within assigned team' do

      context 'awaiting responder state' do
        it 'should show permitted events' do
          k = create :awaiting_responder_sar
          responder = responder_in_assigned_team(k)
          expect(k.current_state).to eq 'awaiting_responder'
          expect(k.state_machine.permitted_events(responder.id)).to eq [:accept_responder_assignment,
                                                                        :add_message_to_case,
                                                                        :reject_responder_assignment]
        end
      end

      context 'drafting state' do
        it 'should show permitted events' do
          k = create :accepted_sar
          responder = responder_in_assigned_team(k)
          expect(k.current_state).to eq 'drafting'
          expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                        :reassign_user,
                                                                        :respond]
        end
      end

      context 'awaiting dispatch state' do
        it 'should show permitted events' do
          k = create :sar_with_response
          responder = responder_in_assigned_team(k)
          expect(k.current_state).to eq 'awaiting_dispatch'
          expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                        :add_responses,
                                                                        :remove_last_response,
                                                                        :remove_response]
                                                                        # :respond
        end
      end

      context 'responded state' do
        it 'should show permitted events' do
          k = create :responded_sar
          responder = responder_in_assigned_team(k)
          expect(k.current_state).to eq 'responded'
          expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case]
        end
      end

      context 'closed state' do
        it 'should show permitted events' do
          k = create :closed_sar, :clarification_required
          responder = responder_in_assigned_team(k)
          expect(k.current_state).to eq 'closed'
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end
    end

    def responder_in_assigned_team(k)
      create :responder, responding_teams: [k.responding_team]
    end
  end
end
