require 'rails_helper'

describe ConfigurableStateMachine::Machine do
  describe 'with standard workflow Offender SAR case' do

    TRANSITIONS = [
      {
        state: :data_to_be_requested,
        specific_events: [
          :preview_cover_page,
          :mark_as_waiting_for_data,
          :send_acknowledgement_letter
        ]
      },
      {
        state: :waiting_for_data,
        specific_events: [
          :preview_cover_page,
          :mark_as_ready_for_vetting,
          :send_acknowledgement_letter,
          :move_case_back
        ]
      },
      {
        state: :ready_for_vetting,
        specific_events: [
          :preview_cover_page,
          :mark_as_vetting_in_progress,
          :move_case_back,
          :record_sent_to_sscl
          :date_sent_to_sscl_removed
        ]
      },
      {
        state: :vetting_in_progress,
        specific_events: [
          :mark_as_ready_to_copy,
          :preview_cover_page,
          :move_case_back,
          :record_sent_to_sscl
          :date_sent_to_sscl_removed
        ]
      },
      {
        state: :ready_to_copy,
        specific_events: [
          :preview_cover_page,
          :mark_as_ready_to_dispatch,
          :move_case_back,
          :record_sent_to_sscl
          :date_sent_to_sscl_removed
        ]
      },
      {
        state: :ready_to_dispatch,
        specific_events: [
          :preview_cover_page,
          :close,
          :send_dispatch_letter,
          :move_case_back,
          :record_sent_to_sscl
          :date_sent_to_sscl_removed
        ]
      },
      {
        state: :closed,
        full_events: [
          :preview_cover_page,
          :add_note_to_case,
          :edit_case,
          :send_dispatch_letter,
          :start_complaint,
          :mark_as_further_actions_required,
          :mark_as_partial_case,
          :unmark_as_further_actions_required,
          :unmark_as_partial_case,
          :mark_as_awaiting_response_for_partial_case,
          :annotate_retention_changes,
          :annotate_system_retention_changes,
          :record_sent_to_sscl
          :date_sent_to_sscl_removed
        ]
      },
    ].freeze

    UNIVERSAL_EVENTS = %i[
      add_note_to_case
      add_data_received
      edit_case
    ].freeze

    def offender_sar_case(with_state:)
      create :offender_sar_case, with_state
    end

    context 'as responder' do
      let(:responder) { find_or_create :branston_user }

      TRANSITIONS.each do |transition|
        context "with Offender SAR in state #{transition[:state]}" do
          let(:kase) { offender_sar_case with_state: transition[:state] }

          before do
            expect(kase.current_state.to_sym).to eq transition[:state]
          end

          it 'only allows permitted events' do
            permitted_events = (transition[:full_events] || UNIVERSAL_EVENTS) +
                                (transition[:specific_events] || [])

            expect(kase.state_machine.permitted_events(responder))
              .to match_array permitted_events
          end

          it "allow start_complaints when the case is open late or closed" do
            if transition[:state] != 'closed'
              kase.external_deadline = Date.today - 1.days
              kase.save!
            end

            expect(kase.state_machine.permitted_events(responder))
              .to include :start_complaint
          end

        end
      end

      it "allow to record reason of lateness when a ready-to-copy case is late " do
        late_kase = create :offender_sar_case, "ready_to_copy", received_date: 2.month.ago
        expect(late_kase.state_machine.permitted_events(responder))
          .to include :capture_reason_for_lateness
        expect(late_kase.state_machine.permitted_events(responder))
          .not_to include :mark_as_ready_to_dispatch
      end

    end
  end
end
