require 'rails_helper'

describe ConfigurableStateMachine::Machine do
  context 'non-flagged case' do
    context 'manager' do
      let(:manager) { create :manager }

      context 'unassigned state' do
        it 'should show permitted events' do
          k = create :overturned_ico_sar
          expect(k.current_state).to eq 'unassigned'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :assign_responder,
                                                                      :destroy_case,
                                                                      :flag_for_clearance,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :request_further_clearance]
        end
      end

      context 'awaiting responder' do
        it 'should show permitted events' do
          k = create :awaiting_responder_ot_ico_sar
          expect(k.current_state).to eq 'awaiting_responder'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :assign_to_new_team,
                                                                      :destroy_case,
                                                                      :flag_for_clearance,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :request_further_clearance]
        end
      end

      context 'drafting' do
        it 'should show permitted events' do
          k = create :accepted_ot_ico_sar
          expect(k.current_state).to eq 'drafting'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :assign_to_new_team,
                                                                      :destroy_case,
                                                                      :flag_for_clearance,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :request_further_clearance,
                                                                      :unassign_from_user]
        end
      end

      context 'closed' do
        it "should show permitted events" do
          k = create :closed_ot_ico_sar
          expect(k.current_state).to eq 'closed'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :assign_to_new_team,
                                                                      :destroy_case,
                                                                      :link_a_case,
                                                                      :remove_linked_case]
        end
      end
    end

    context 'not in assigned team' do
      let(:responder) { create :responder }

      context 'unassigned state' do
        it 'should show permitted events' do
          k = create :overturned_ico_sar
          expect(k.current_state).to eq 'unassigned'
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end

      context 'awaiting responder state' do
        it 'should show permitted events' do
          k = create :awaiting_responder_ot_ico_sar
          expect(k.current_state).to eq 'awaiting_responder'
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end

      context 'drafting state' do
        it 'should show permitted events' do
          k = create :accepted_ot_ico_sar
          expect(k.current_state).to eq 'drafting'
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end

      context 'closed state' do
        it 'should show permitted events' do
          k = create :closed_ot_ico_sar
          expect(k.current_state).to eq 'closed'
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end
    end



    context 'within assigned team' do

      context 'awaiting responder state' do
        it 'should show permitted events' do
          k = create :awaiting_responder_ot_ico_sar
          responder = responder_in_assigned_team(k)
          expect(k.current_state).to eq 'awaiting_responder'
          expect(k.state_machine.permitted_events(responder.id)).to eq [:accept_responder_assignment,
                                                                        :add_message_to_case,
                                                                        :reject_responder_assignment]
        end
      end

      context 'drafting state' do
        it 'should show permitted events' do
          k = create :accepted_ot_ico_sar
          responder = responder_in_assigned_team(k)
          expect(k.current_state).to eq 'drafting'
          expect(k.state_machine.permitted_events(responder.id)).to eq [:add_message_to_case,
                                                                        :close,
                                                                        :reassign_user,
                                                                        :respond,
                                                                        :respond_and_close]
        end
      end

      context 'closed state' do
        it 'should show permitted events' do
          k = create :closed_ot_ico_sar
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
