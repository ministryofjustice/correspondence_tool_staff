require "rails_helper"

describe ConfigurableStateMachine::Machine do # rubocop:disable RSpec/FilePath
  describe "with standard workflow Offender SAR Complaint case" do
    def universal_events_standards
      %i[
        add_note_to_case
        edit_case
        reassign_user
      ]
    end

    context "when responder" do
      let(:responder) { find_or_create :branston_user }

      [
        {
          state: :to_be_assessed,
          specific_events: %i[
            mark_as_require_data_review
            mark_as_data_to_be_requested
            mark_as_require_response
            preview_cover_page
            send_acknowledgement_letter
            reset_to_initial_state
          ],
        },
        {
          state: :data_review_required,
          specific_events: %i[
            mark_as_vetting_in_progress
            mark_as_require_response
            send_acknowledgement_letter
            preview_cover_page
            add_data_received
            reset_to_initial_state
          ],
        },
        {
          state: :data_to_be_requested,
          specific_events: %i[
            mark_as_waiting_for_data
            send_acknowledgement_letter
            preview_cover_page
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
            reset_to_initial_state
            add_data_received
          ],
        },
        {
          state: :ready_for_vetting,
          specific_events: %i[
            mark_as_vetting_in_progress
            preview_cover_page
            reset_to_initial_state
            add_data_received
          ],
        },
        {
          state: :vetting_in_progress,
          specific_events: %i[
            mark_as_ready_to_copy
            mark_as_second_vetting_in_progress
            preview_cover_page
            reset_to_initial_state
            add_data_received
          ],
        },
        {
          state: :ready_to_copy,
          specific_events: %i[
            preview_cover_page
            mark_as_require_response
            reset_to_initial_state
            add_data_received
          ],
        },
        {
          state: :response_required,
          specific_events: %i[
            preview_cover_page
            close
            send_dispatch_letter
            reset_to_initial_state
            add_data_received
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
            reset_to_initial_state
          ],
        },
      ].each do |transition|
        context "with Offender SAR Complaint in state #{transition[:state]}" do
          it "only allows permitted events" do
            kase = create :accepted_complaint_case, transition[:state], complaint_type: "standard_complaint"
            expect(kase.current_state.to_sym).to eq transition[:state]
            permitted_events = (transition[:full_events] || universal_events_standards) +
              (transition[:specific_events] || [])

            expect(kase.state_machine.permitted_events(responder))
              .to match_array permitted_events
          end
        end
      end
    end
  end
end
