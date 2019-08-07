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
          expect(k.state_machine.permitted_events(manager)).to eq [:add_note_to_case,
                                                                   :mark_as_waiting_for_data]
        end
      end


      context 'waiting for data state' do
        it 'shows events' do
          k = create :waiting_for_data_offender_sar
          expect(k.class).to eq Case::SAR::Offender
          expect(k.workflow).to eq 'standard'
          expect(k.current_state).to eq 'waiting_for_data'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_note_to_case,
                                                                      :mark_as_ready_for_vetting]
        end
      end

      context 'ready for vetting state' do
        it 'shows events' do
          k = create :ready_for_vetting_offender_sar
          expect(k.class).to eq Case::SAR::Offender
          expect(k.workflow).to eq 'standard'
          expect(k.current_state).to eq 'ready_for_vetting'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_note_to_case,
                                                                      :mark_as_vetting_in_progress]
        end
      end

      context 'vetting in progress state' do
        it 'shows events' do
          k = create :vetting_in_progress_offender_sar
          expect(k.class).to eq Case::SAR::Offender
          expect(k.workflow).to eq 'standard'
          expect(k.current_state).to eq 'vetting_in_progress'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_note_to_case,
                                                                      :mark_as_ready_to_copy]
        end
      end

      context 'ready to copy state' do
        it 'shows events' do
          k = create :ready_to_copy_offender_sar
          expect(k.class).to eq Case::SAR::Offender
          expect(k.workflow).to eq 'standard'
          expect(k.current_state).to eq 'ready_to_copy'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_note_to_case,
                                                                      :mark_as_ready_to_dispatch]
        end
      end

      context 'ready to dispatch state' do
        it 'shows events' do
          k = create :ready_to_dispatch_offender_sar
          expect(k.class).to eq Case::SAR::Offender
          expect(k.workflow).to eq 'standard'
          expect(k.current_state).to eq 'ready_to_dispatch'
          expect(k.state_machine.permitted_events(manager.id)).to eq [:add_note_to_case,
                                                                      :mark_as_closed]
        end
      end
    end
  end
end
