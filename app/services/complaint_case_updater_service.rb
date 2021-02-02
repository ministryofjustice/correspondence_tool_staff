class ComplaintCaseUpdaterService < CaseUpdaterService
  attr_reader :result

  INITAL_CASE_STATUS = 'to_be_assessed'

  def call
    reset_status_on_complaint_type_change
    super
  end

  private

  def reset_status_on_complaint_type_change
    case_type = @kase.complaint_type
    params_case_type = @params['complaint_type']
    if case_type != params_case_type && params_case_type.present?
      @kase.current_state = INITAL_CASE_STATUS
    end
  end
end
