require "rails_helper"

TRANSITIONS_ICO = [
  {
    state: :to_be_assessed,
    specific_events: %i[
      preview_cover_page
      mark_as_require_data_review
      mark_as_data_to_be_requested
      mark_as_require_response
      send_acknowledgement_letter
      reset_to_initial_state
    ],
  },
  {
    state: :data_review_required,
    specific_events: %i[
      preview_cover_page
      mark_as_vetting_in_progress
      mark_as_require_response
      send_acknowledgement_letter
      reset_to_initial_state
      add_data_received
    ],
  },
  {
    state: :data_to_be_requested,
    specific_events: %i[
      preview_cover_page
      mark_as_waiting_for_data
      send_acknowledgement_letter
      add_data_received
      reset_to_initial_state
    ],
  },
  {
    state: :waiting_for_data,
    specific_events: %i[
      mark_as_ready_for_vetting
      mark_as_require_response
      send_acknowledgement_letter
      preview_cover_page
      add_data_received
      reset_to_initial_state
    ],
  },
  {
    state: :ready_for_vetting,
    specific_events: %i[
      mark_as_vetting_in_progress
      preview_cover_page
      add_data_received
      reset_to_initial_state
    ],
  },
  {
    state: :vetting_in_progress,
    specific_events: %i[
      mark_as_ready_to_copy
      mark_as_second_vetting_in_progress
      preview_cover_page
      add_data_received
      reset_to_initial_state
    ],
  },
  {
    state: :ready_to_copy,
    specific_events: %i[
      preview_cover_page
      mark_as_require_response
      add_data_received
      reset_to_initial_state
    ],
  },
  {
    state: :response_required,
    specific_events: %i[
      close
      preview_cover_page
      send_dispatch_letter
      add_complaint_appeal_outcome
      add_data_received
      add_approval_flags_for_ico
      reset_to_initial_state
    ],
  },
  {
    state: :closed,
    full_events: %i[
      preview_cover_page
      add_note_to_case
      edit_case
      annotate_retention_changes
      annotate_system_retention_changes
      send_dispatch_letter
      add_complaint_appeal_outcome
      add_approval_flags_for_ico
      reset_to_initial_state
    ],
  },
].freeze

UNIVERSAL_EVENTS_ICO = %i[
  add_note_to_case
  edit_case
  reassign_user
].freeze

describe ConfigurableStateMachine::Machine do # rubocop:disable RSpec/FilePath
  describe "with ico workflow Offender SAR Complaint case" do
    context "when responder" do
      let(:responder) { find_or_create :branston_user }

      TRANSITIONS_ICO.each do |transition|
        context "with Offender SAR Complaint in state #{transition[:state]}" do
          it "only allows permitted events" do
            kase = create :accepted_complaint_case, transition[:state], complaint_type: "ico_complaint"
            expect(kase.current_state.to_sym).to eq transition[:state]

            permitted_events = (transition[:full_events] || UNIVERSAL_EVENTS_ICO) +
              (transition[:specific_events] || [])

            expect(kase.state_machine.permitted_events(responder))
              .to match_array permitted_events
          end
        end
      end
    end
  end
end
