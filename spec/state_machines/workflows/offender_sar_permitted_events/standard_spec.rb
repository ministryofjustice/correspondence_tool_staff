require 'rails_helper'

describe ConfigurableStateMachine::Machine do
  describe 'with standard workflow Offender SAR case' do

    TRANSITIONS = [
      {
        state: :data_to_be_requested,
        specific_events: [:mark_as_waiting_for_data, :send_acknowledgement_letter]
      },
      {
        state: :waiting_for_data,
        specific_events: [:mark_as_ready_for_vetting, :send_acknowledgement_letter]
      },
      {
        state: :ready_for_vetting,
        specific_events: [:mark_as_vetting_in_progress]
      },
      {
        state: :vetting_in_progress,
        specific_events: [:mark_as_ready_to_copy]
      },
      {
        state: :ready_to_copy,
        specific_events: [:mark_as_ready_to_dispatch]
      },
      {
        state: :ready_to_dispatch,
        specific_events: [:close, :send_dispatch_letter]
      },
    ].freeze

    UNIVERSAL_EVENTS = %i[
      add_note_to_case
      add_data_received
    ].freeze

    def offender_sar_case(with_state:)
      create :offender_sar_case, with_state
    end

    context 'as manager' do
      let(:manager) { find_or_create :disclosure_bmt_user }

      TRANSITIONS.each do |transition|
        context "with Offender SAR in state #{transition[:state]}" do
          let(:kase) { offender_sar_case with_state: transition[:state] }

          before do
            expect(kase.current_state.to_sym).to eq transition[:state]
          end

          it 'only allows permitted events' do
            permitted_events = UNIVERSAL_EVENTS + transition[:specific_events]

            expect(kase.state_machine.permitted_events(manager))
              .to match_array permitted_events
          end
        end
      end
    end
  end
end
