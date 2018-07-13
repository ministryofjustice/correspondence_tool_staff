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


  def process_new_linked_cases_for_params
    case @correspondence_type_key
    when 'ico' then process_new_linked_cases_for_ico_params
    else raise "Unknown case type: #{@correspondence_type_key}"
    end
  end

  def process_new_linked_cases_for_ico_params
    case @link_type
    when 'original' then process_new_linked_cases_for_ico_original_params
    when 'related'  then process_new_linked_cases_for_ico_related_params
    else raise "unknown link type: '#{@link_type}"
    end
  end

  def process_new_linked_cases_for_ico_original_params
    if params.key?(:original_case_number).nil?
      @linked_case_error = "Enter original case number"
      return false
    end

    original_case = Case::Base.where(number: params[:original_case_number]).first
    unless original_case.present?
      @linked_case_error = "Original case not found"
      return false
    end

    @linked_cases = [original_case]
    true
  end

  def process_new_linked_cases_for_ico_related_params
    if params.key?(:related_case_number).nil?
      @linked_case_error = "Enter related case number"
      return false
    end

    related_case = Case::Base.where(number: params[:related_case_number]).first
    unless related_case.present?
      @linked_case_error = "Related case not found"
      return false
    end

    original_case = Case::Base.find_by(number: params.fetch(:original_case_number))
    if related_case.correspondence_type != original_case.correspondence_type
      @linked_case_error =
        "Related case type #{related_case.type_abbreviation} does not match " +
        "that of the original case type #{original_case.type_abbreviation}"
      return false
    end

    if params.fetch(:related_case_ids).present?
      @linked_cases = Case::Base.find(params[:related_case_ids])
      @linked_cases += [related_case]
    else
      @linked_cases = [related_case]
    end

    true
  end

end
