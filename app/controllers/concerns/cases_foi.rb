module CasesFOI
  extend ActiveSupport::Concern

  def create_foi_params
    params.require(:case_foi).permit(
      :requester_type,
      :name,
      :postal_address,
      :email,
      :subject,
      :message,
      :received_date_dd, :received_date_mm, :received_date_yyyy,
      :delivery_method,
      :flag_for_disclosure_specialists,
      uploaded_request_files: [],
    )
  end
end
