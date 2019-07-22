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
                                                                   :mark_as_next_state]
        end
      end


      context 'waiting for data state' do
        it 'shows events' do
          k = create :waiting_for_data_offender_sar
          expect(k.class).to eq Case::SAR::Offender
          expect(k.workflow).to eq 'standard'
          expect(k.current_state).to eq 'waiting_for_data'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :mark_as_next_state]
        end
      end

      context 'ready for vetting state' do
        it 'shows events' do
          k = create :ready_for_vetting_offender_sar
          expect(k.class).to eq Case::SAR::Offender
          expect(k.workflow).to eq 'standard'
          expect(k.current_state).to eq 'ready_for_vetting'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :mark_as_next_state]
        end
      end

      context 'vetting in progress state' do
        it 'shows events' do
          k = create :vetting_in_progress_offender_sar
          expect(k.class).to eq Case::SAR::Offender
          expect(k.workflow).to eq 'standard'
          expect(k.current_state).to eq 'vetting_in_progress'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :mark_as_next_state]
        end
      end

      context 'ready to dispatch state' do
        it 'shows events' do
          k = create :ready_to_dispatch_offender_sar
          expect(k.class).to eq Case::SAR::Offender
          expect(k.workflow).to eq 'standard'
          expect(k.current_state).to eq 'ready_to_dispatch'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :mark_as_next_state]
        end
      end

      context 'ready to close state' do
        it 'shows events' do
          k = create :ready_to_close_offender_sar
          expect(k.class).to eq Case::SAR::Offender
          expect(k.workflow).to eq 'standard'
          expect(k.current_state).to eq 'ready_to_close'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_message_to_case,
                                                                      :mark_as_next_state]
        end
      end
    end
  end
end
