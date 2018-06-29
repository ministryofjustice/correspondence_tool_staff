module CasesICO
  extend ActiveSupport::Concern

  def create_ico_params
    params.require(:case_ico).permit(
      :ico_reference_number,
      :subject,
      :message,
      :received_date_dd, :received_date_mm, :received_date_yyyy,
      :external_deadline_dd, :external_deadline_mm, :external_deadline_yyyy,
      uploaded_request_files: [],
    )

  end

  def get_ico_case_class_from_params(params)
    case params[:case_ico].fetch(:original_case_type).downcase
    when 'foi' then Case::ICO::FOI
    when 'sar' then Case::ICO::SAR
    end
  end
end
