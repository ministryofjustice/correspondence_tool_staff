require './lib/translate_for_case'

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
      @user.permitted_correspondence_types.each do | correspondence_type |
        correspondence_type.sub_classes.each do | sub_class|
          sub_class.permitted_states.map do | state |
            state_choices[state] =  TranslateForCase.translate(sub_class, 'state', state)
          end
        end 
      end 
      { :filter_open_case_status => state_choices }
    end

  end
end

