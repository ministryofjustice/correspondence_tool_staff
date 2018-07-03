module CasesSAR
  extend ActiveSupport::Concern

  def create_sar_params
    params.require(:case_sar).permit(
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
      uploaded_request_files: [],
    )
  end
end
