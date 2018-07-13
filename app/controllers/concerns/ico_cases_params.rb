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

  def validate_ico_linked_cases_for_params
    if params[:link_to] == 'original'
      validate_ico_linked_cases_for_original_params
    end
  end

  def validate_ico_linked_cases_for_original_params
      if params.key?(:original_case_number)
        @original_case = Case::Base.where(number: params[:original_case_number]).first
        if @original_case.present?
          true
        else
          @linked_case_errors = "Original case not found"
          false
        end
      else
        @linked_case_errors = "Enter original case number"
        false
    end
  end

end
