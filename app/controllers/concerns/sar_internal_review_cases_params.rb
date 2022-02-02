module SARInternalReviewCasesParams
  extend ActiveSupport::Concern

  def create_sar_internal_review_params
    process_third_party_details(params)
    params.require(:sar_internal_review).permit(
      :delivery_method,
      :email,
      :flag_for_disclosure_specialists,
      :message,
      :name,
      :postal_address,
      :received_date_dd, :received_date_mm, :received_date_yyyy,
      :requester_type,
      :sar_ir_subtype,
      :subject,
      :subject_full_name,
      :subject_type,
      :third_party,
      :third_party_relationship,
      :reply_method,
      :original_case_number,
      :original_case_id,
      uploaded_request_files: [],
    )
  end

  def edit_sar_internal_review_params
    process_third_party_details(params)
    params.require(:sar_internal_review).permit(
      :delivery_method,
      :email,
      :flag_for_disclosure_specialists,
      :message,
      :name,
      :postal_address,
      :received_date_dd, :received_date_mm, :received_date_yyyy,
      :requester_type,
      :sar_ir_subtype,
      :subject,
      :subject_full_name,
      :subject_type,
      :third_party,
      :third_party_relationship,
      :reply_method,
      uploaded_request_files: [],
    )
  end

  def process_sar_internal_review_closure_params
    params.require(:sar_internal_review).permit(
      :date_responded_dd,
      :date_responded_mm,
      :date_responded_yyyy,
      :sar_ir_outcome,
      :late_team_id,
      :team_responsible_for_outcome_id,
      outcome_reason_ids: []
    ).merge(refusal_reason_abbreviation: missing_info_to_tmm)
  end

  def respond_sar_internal_review_params
    params.require(:sar_internal_review).permit(
      :date_responded_dd,
      :date_responded_mm,
      :date_responded_yyyy,
    )
  end

  private

  def missing_info_to_tmm
    if params[:sar_internal_review][:missing_info] == "yes"
      @case.missing_info = true
      CaseClosure::RefusalReason.sar_tmm.abbreviation
    elsif params[:sar_internal_review][:missing_info] == "no"
      @case.missing_info = false
    end
  end

  def process_third_party_details(params)
    third_party = params[:sar_internal_review][:third_party]
    request_not_on_others_behalf = third_party == "false" 

    if request_not_on_others_behalf
      params[:sar_internal_review][:name] = nil
      params[:sar_internal_review][:third_party_relationship] = nil
    end
  end
end
