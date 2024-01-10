require "./lib/translate_for_case"

module CaseFilter
  class OpenCaseStatusFilter < CaseMultiChoicesFilterBase
    def self.identifier
      "filter_open_case_status"
    end

    def self.filter_attributes
      [:filter_open_case_status]
    end

    def call
      if @query.filter_open_case_status.any?
        @records = @records.where(current_state: @query.filter_open_case_status)
      end
      @records
    end

    def available_choices
      state_choices = {}
      @user.permitted_correspondence_types.each do |correspondence_type|
        correspondence_type.sub_classes.each do |sub_class|
          (sub_class.permitted_states - ConfigurableStateMachine::Machine.states_for_closed_cases).map do |state|
            state_choices[state] = get_tranlation_of_state_for_filter(sub_class, state)
          end
        end
      end

      offender_sar_move_state_filter_option_to_end(state_choices, "rejected")

      { filter_open_case_status: state_choices }
    end

  private

    # For users dealing with Offender SARs
    # To ensure 'rejected' is at the end of the filter list, .delete returns the
    # value of the given key. It is then immediately assigned back.
    def offender_sar_move_state_filter_option_to_end(filters, filter_key)
      if @user.permitted_correspondence_types.any? { |h| h[:abbreviation] == "OFFENDER_SAR" }
        filters[filter_key] = filters.delete(filter_key)
      end
    end

    def get_tranlation_of_state_for_filter(sub_class, state)
      I18n.t("filters.filter_open_case_status.#{state}", default: nil) || TranslateForCase.translate(sub_class, "state", state)
    end
  end
end
