module Cases
  class NotesController < ApplicationController
    before_action :set_case, :set_date_of_birth

    def create
      begin
        @case.state_machine.add_note_to_case!(
          acting_user: current_user,
          acting_team: case_team,
          message: params[:case][:message_text]
        )
      rescue ActiveRecord::RecordInvalid => err
        if err.record.errors.include?(:message)
          flash[:case_errors] = { message_text: err.record.errors[:message] }
        end
      ensure
        redirect_to case_path(@case, anchor: 'case-history')
      end
    end

    private

    # need to sort with manager first so that if we are both manager and something else, we don't
    # try to execute the action with our lower authority (which might fail)
    def case_team
      User.sort_teams_by_roles(case_teams).first
    end

    def case_teams
      if current_user.teams_for_case(@case).any?
        current_user.teams_for_case(@case)
      else
        current_user.teams
      end
    end

    def set_case
      @case = Case::Base.find(params[:case_id])
      authorize(@case, :can_add_note_to_case?)
    end

    # this method is here to fix an issue with the gov_uk_date_fields
    # where the validation fails since the internal list of instance
    # variables lacks the date_of_birth field from the json properties
    #     NoMethodError: undefined method `valid?' for nil:NilClass
    #     ./app/state_machines/configurable_state_machine/machine.rb:256
    def set_date_of_birth
      @case.date_of_birth = @case.date_of_birth
    end
  end
end
