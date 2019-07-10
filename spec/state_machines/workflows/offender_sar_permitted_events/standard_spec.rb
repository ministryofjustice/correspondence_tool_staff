require 'rails_helper'

describe ConfigurableStateMachine::Machine do
  context 'standard workflow' do

##################### MANAGER  ############################

    context 'manager' do

      let(:manager)   { find_or_create :disclosure_bmt_user}

      context 'data to be requested state' do
        it 'should show permitted events' do
          k = create :offender_sar_case
          expect(k.class).to eq Case::SAR::Offender
          expect(k.workflow).to eq 'standard'
          expect(k.current_state).to eq 'data_to_be_requested'
          expect(k.state_machine.permitted_events(manager)).to eq [:add_message_to_case,
                                                                   :mark_as_waiting_for_data]
        end
      end


      context 'waiting for data state' do
        it 'shows events' do
          k = create :waiting_for_data_offender_sar
          expect(k.class).to eq Case::SAR::Offender
          expect(k.workflow).to eq 'standard'
          expect(k.current_state).to eq 'waiting_for_data'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case]
        end
      end

      context 'ready for vetting state' do
        it 'shows events' do
          k = create :accepted_ot_ico_foi
          expect(k.class).to eq Case::OverturnedICO::FOI
          expect(k.workflow).to eq 'standard'
          expect(k.current_state).to eq 'drafting'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :assign_to_new_team,
                                                                      :destroy_case,
                                                                      :extend_for_pit,
                                                                      :flag_for_clearance,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :request_further_clearance,
                                                                      :unassign_from_user]
        end
      end

      context 'vetting in progress state' do
        it 'shows events' do
          k = create :with_response_ot_ico_foi
          expect(k.class).to eq Case::OverturnedICO::FOI
          expect(k.workflow).to eq 'standard'
          expect(k.current_state).to eq 'awaiting_dispatch'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :destroy_case,
                                                                      :extend_for_pit,
                                                                      :flag_for_clearance,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :request_further_clearance,
                                                                      :unassign_from_user]
        end
      end

      context 'ready to dispatch state' do
        it 'shows events' do
          k = create :responded_ot_ico_foi
          expect(k.class).to eq Case::OverturnedICO::FOI
          expect(k.workflow).to eq 'standard'
          expect(k.current_state).to eq 'responded'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :close,
                                                                      :destroy_case,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :unassign_from_user]
        end
      end

      context 'ready to close state' do
        it 'shows events' do
          k = create :closed_ot_ico_foi
          expect(k.class).to eq Case::OverturnedICO::FOI
          expect(k.workflow).to eq 'standard'
          expect(k.current_state).to eq 'closed'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :assign_to_new_team,
                                                                      :destroy_case,
                                                                      :link_a_case,
                                                                      :remove_linked_case,
                                                                      :update_closure]
        end
      end
    end
  end
end
