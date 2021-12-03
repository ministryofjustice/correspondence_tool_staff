module SARInternalReviewCasesParams
  extend ActiveSupport::Concern

  def create_sar_internal_review_params
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

end
