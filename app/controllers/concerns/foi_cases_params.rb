module FoiCasesParams
  extend ActiveSupport::Concern

  def create_foi_params
    params.require(:foi).permit(
      :requester_type,
      :type,
      :name,
      :postal_address,
      :email,
      :subject,
      :message,
      :received_date_dd, :received_date_mm, :received_date_yyyy,
      :delivery_method,
      :flag_for_disclosure_specialists,
      uploaded_request_files: []
    )
  end

  def edit_foi_params
    params.require(:foi).permit(
      :requester_type,
      :type,
      :name,
      :postal_address,
      :email,
      :subject,
      :message,
      :received_date_dd, :received_date_mm, :received_date_yyyy,
      :date_draft_compliant_dd, :date_draft_compliant_mm, :date_draft_compliant_yyyy,
      :delivery_method,
      :flag_for_disclosure_specialists,
      uploaded_request_files: []
    )
  end

  def process_foi_closure_params
    closure_params = params.require(:foi).permit(
      :date_responded_dd,
      :date_responded_mm,
      :date_responded_yyyy,
      :outcome_abbreviation,
      :appeal_outcome_name,
      :refusal_reason_abbreviation,
      :info_held_status_abbreviation,
      :late_team_id,
      exemption_ids: [],
    )

    info_held_status = closure_params[:info_held_status_abbreviation]
    outcome          = closure_params[:outcome_abbreviation]
    refusal_reason   = closure_params[:refusal_reason_abbreviation]

    unless ClosedCaseValidator.outcome_required?(info_held_status:)
      closure_params.merge!(outcome_id: nil)
      closure_params.delete(:outcome_abbreviation)
    end

    unless ClosedCaseValidator.refusal_reason_required?(info_held_status:)
      closure_params.merge!(refusal_reason_id: nil)
      closure_params.delete(:refusal_reason_abbreviation)
    end

    unless ClosedCaseValidator.exemption_required?(info_held_status:,
                                                   outcome:,
                                                   refusal_reason:)
      closure_params.merge!(exemption_ids: [])
    end

    closure_params
  end

  def respond_foi_params
    params.require(:foi).permit(
      :date_responded_dd,
      :date_responded_mm,
      :date_responded_yyyy,
    )
  end
end
