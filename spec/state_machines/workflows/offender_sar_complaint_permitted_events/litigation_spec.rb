require 'rails_helper'

describe ConfigurableStateMachine::Machine do
  describe 'with litigation workflow Offender SAR Complaint case' do

    TRANSITIONS = [
      {
        state: :to_be_assessed,
        specific_events: [
          :mark_as_require_data_review, 
          :mark_as_data_to_be_requested,
          :mark_as_require_response, 
          :mark_as_waiting,
          :send_acknowledgement_letter]
      },
      {
        state: :data_review_required, 
        specific_events: [
          :mark_as_ready_to_copy, 
          :mark_as_require_response,
          :send_acknowledgement_letter]
      },
      {
        state: :waiting, 
        specific_events: [
          :mark_as_data_to_be_requested, 
          :send_acknowledgement_letter]
      },
      {
        state: :data_to_be_requested,
        specific_events: [
          :mark_as_waiting_for_data, 
          :send_acknowledgement_letter]
      },
      {
        state: :waiting_for_data,
        specific_events: [
          :mark_as_ready_for_vetting,
          :send_acknowledgement_letter, 
          :preview_cover_page]
      },
      {
        state: :ready_for_vetting,
        specific_events: [
          :mark_as_vetting_in_progress, 
          :preview_cover_page]
      },
      {
        state: :vetting_in_progress,
        specific_events: [
          :mark_as_ready_to_copy, 
          :preview_cover_page]
      },
      {
        state: :ready_to_copy,
        specific_events: [
          :mark_as_ready_to_dispatch]
      },
      {
        state: :ready_to_dispatch,
        specific_events: [:close, :send_dispatch_letter]
      },
      {
        state: :response_required,
        specific_events: [:close, :send_dispatch_letter]
      },
      {
        state: :closed,
        full_events: [:add_note_to_case, :edit_case, :send_dispatch_letter]
      },
    ].freeze

    UNIVERSAL_EVENTS = %i[
      add_note_to_case
      add_data_received
      edit_case
      reassign_user
    ].freeze


    context 'as responder' do
      let(:responder) { find_or_create :branston_user }

      TRANSITIONS.each do |transition|
        context "with Offender SAR Complaint in state #{transition[:state]}" do
          it 'only allows permitted events' do
            kase = create :accepted_complaint_case, transition[:state], complaint_type: 'litigation_complaint' 
            expect(kase.current_state.to_sym).to eq transition[:state]
            permitted_events = (transition[:full_events] || UNIVERSAL_EVENTS) + 
                                (transition[:specific_events] || [])

            expect(kase.state_machine.permitted_events(responder))
              .to match_array permitted_events
          end
        end
      end
    end
  end
end
