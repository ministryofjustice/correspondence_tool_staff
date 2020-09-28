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
      collected_states = []
      @user.permitted_correspondence_types.each do | correspondence_type |
        correspondence_type.sub_classes.each do | sub_class|
          collected_states.push(*sub_class.permitted_states)
        end 
      end 
      state_choices = {}
      (collected_states.uniq - ConfigurableStateMachine::Machine.states_for_closed_cases).each do | state |
        state_choices[state] = I18n.t("filters.filter_open_case_status.#{state}")
      end
      { :filter_open_case_status => state_choices }
    end

  end
end

