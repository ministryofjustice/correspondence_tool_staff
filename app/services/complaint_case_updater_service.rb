class ComplaintCaseUpdaterService < CaseUpdaterService
  attr_reader :result

  def call
    reset_status_on_complaint_type_change
    super
  end

private

  def reset_status_on_complaint_type_change
    if current_case_type_doesnt_match_selected_case_type
      reset_case_status_to_default_state
    end
  end

  def reset_case_status_to_default_state
    @kase.state_machine.reset_to_initial_state!(acting_user: @user, acting_team: @team)
  end

  def current_case_type_doesnt_match_selected_case_type
    case_type = @kase.complaint_type_in_database
    params_case_type = @params["complaint_type"]

    case_type != params_case_type && params_case_type.present?
  end
end
