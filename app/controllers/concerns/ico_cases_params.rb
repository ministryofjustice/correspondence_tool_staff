module ICOCasesParams
  extend ActiveSupport::Concern

  def create_ico_params
    params.require(:case_ico).permit(
      :ico_reference_number,
      :subject,
      :message,
      :original_case_id,
      :received_date_dd, :received_date_mm, :received_date_yyyy,
      :external_deadline_dd, :external_deadline_mm, :external_deadline_yyyy,
      uploaded_request_files: [],
    )
  end
end
