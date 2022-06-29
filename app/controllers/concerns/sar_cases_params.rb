module SARCasesParams
  extend ActiveSupport::Concern

  def create_sar_params
    params.require(:sar).permit(
      :delivery_method,
      :email,
      :flag_for_disclosure_specialists,
      :message,
      :name,
      :postal_address,
      :received_date_dd, :received_date_mm, :received_date_yyyy,
      :requester_type,
      :subject,
      :subject_full_name,
      :subject_type,
      :third_party,
      :third_party_relationship,
      :reply_method,
      :request_method,
      uploaded_request_files: [],
    )
  end

  def edit_sar_params
    params.require(:sar).permit(
      :subject_full_name,
      :subject_type,
      :third_party,
      :third_party_relationship,
      :name,
      :received_date_dd, :received_date_mm, :received_date_yyyy,
      :date_draft_compliant_dd, :date_draft_compliant_mm, :date_draft_compliant_yyyy,
      :subject,
      :message,
      :flag_for_disclosure_specialists,
      :reply_method,
      :request_method,
      :email,
      :postal_address
    )
  end

  def process_sar_closure_params
    params.require(:sar).permit(
      :date_responded_dd,
      :date_responded_mm,
      :date_responded_yyyy,
      :late_team_id,
    ).merge(refusal_reason_abbreviation: missing_info_to_tmm)
  end

  def respond_sar_params
    params.require(:sar).permit(
      :date_responded_dd,
      :date_responded_mm,
      :date_responded_yyyy,
    )
  end

  def missing_info_to_tmm
    if params[:sar][:missing_info] == "yes"
      @case.missing_info = true
      CaseClosure::RefusalReason.sar_tmm.abbreviation
    elsif params[:sar][:missing_info] == "no"
      @case.missing_info = false
    end
  end
end
