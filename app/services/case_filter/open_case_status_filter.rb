module CaseFilter
  class OpenCaseStatusFilter < CaseFilterBase

    def self.filter_attributes
      [:filter_open_case_status]
    end

    # def applied?
    #   @query.filter_open_case_status.present?
    # end

    def call
      if @query.filter_open_case_status.any?
        @records = @records.where(current_state: @query.filter_open_case_status)
      end
      @records
    end

    def crumbs
      if applied?
        status_text = I18n.t(
          "filters.open_case_statuses.#{@query.filter_open_case_status.first}"
        )
        crumb_text = I18n.t "filters.crumbs.open_case_status",
                            count: @query.filter_open_case_status.size,
                            first_value: status_text,
                            remaining_values_count: @query.filter_open_case_status.count - 1
        params = {
          'filter_open_case_status' => [''],
          'parent_id'               => @query.id
        }
        [[crumb_text, params]]
      else
        []
      end
    end

    def get_available_choices
      collected_states = []
      @user.permitted_correspondence_types.each do | correspondence_type |
        correspondence_type.sub_classes.each do | sub_class|
          collected_states.push(*sub_class.permitted_states)
        end 
      end 
      state_choices = {}
      (collected_states.uniq - ConfigurableStateMachine::Machine.states_for_closed_cases).each do | state |
        state_choices[state] = I18n.t("filters.open_case_statuses.#{state}")
      end
      { :filter_open_case_status => state_choices }
    end

  end
end

