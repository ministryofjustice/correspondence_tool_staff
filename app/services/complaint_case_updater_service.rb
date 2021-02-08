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
    @kase.current_state = @kase.state_machine.initial_state 
  end

  def current_case_type_doesnt_match_selected_case_type
    case_type = @kase.complaint_type
    params_case_type = @params['complaint_type']

    complaint_type_mapping(case_type) != params_case_type && params_case_type.present?
  end

  def complaint_type_mapping(case_complaint_type)
    {
      'Litigation': 'litigation_complaint',
      'ICO': 'ico_complaint',
      'Standard': 'standard_complaint'
    }[case_complaint_type.to_sym]
  end
end
