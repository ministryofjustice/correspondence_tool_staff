module ICOCasesParams
  extend ActiveSupport::Concern

  private

  def create_ico_params
    case_params = params.require(:ico)

    if case_params[:original_case_ids].present?
      case_params[:original_case_id] = case_params.delete(:original_case_ids).first
    end

    case_params.permit(
      :ico_officer_name,
      :ico_reference_number,
      :message,
      :original_case_id,
      :received_date_dd, :received_date_mm, :received_date_yyyy,
      :external_deadline_dd, :external_deadline_mm, :external_deadline_yyyy,
      :internal_deadline_dd, :internal_deadline_mm, :internal_deadline_yyyy,
      :date_draft_compliant_dd, :date_draft_compliant_mm, :date_draft_compliant_yyyy,
      related_case_ids: [],
      uploaded_request_files: [],
    )
  end

  def edit_ico_params
    case_params = params.require(:ico)

    case_params.permit(
      :ico_officer_name,
      :ico_reference_number,
      :message,
      :received_date_dd, :received_date_mm, :received_date_yyyy,
      :external_deadline_dd, :external_deadline_mm, :external_deadline_yyyy,
      :internal_deadline_dd, :internal_deadline_mm, :internal_deadline_yyyy,
      :date_draft_compliant_dd, :date_draft_compliant_mm, :date_draft_compliant_yyyy,
      related_case_ids: [],
      original_case_ids: [],
      uploaded_request_files: [],
    )
  end

  def record_late_team_ico_params
    if params[:ico].present?
      params.require(:ico).permit(:late_team_id)
    else
      {}
    end
  end

  def process_new_linked_cases_for_params
    result = case @correspondence_type_key
             when 'ico' then process_new_linked_cases_for_ico_params
             else raise "Unknown case type: #{@correspondence_type_key}"
             end

    # We've already checked if the new case being added is authorised, and
    # added an appropriate error if not. Here we just ruthlessly remove any
    # other cases that might have snuck in that aren't authorised.
    @linked_cases&.delete_if { |kase| not policy(kase).show? }

    result
  end

  def process_ico_closure_params
    params.require(:ico).permit(
      :date_ico_decision_received_dd,
      :date_ico_decision_received_mm,
      :date_ico_decision_received_yyyy,
      :ico_decision_comment,
      :ico_decision,
      :late_team_id,
      uploaded_ico_decision_files: [],
    )
  end

  def process_new_linked_cases_for_ico_params
    case @link_type
    when 'original' then process_new_linked_cases_for_ico_original_params
    when 'related'  then process_new_linked_cases_for_ico_related_params
    else raise "unknown link type: '#{@link_type}"
    end
  end

  def process_new_linked_cases_for_ico_original_params
    original_case_number = params[:original_case_number].strip
    case_link = LinkedCase.new(
      linked_case_number: original_case_number,
      type: :original
    )

    if case_link.valid?
      original_case = case_link.linked_case

      if validate_ico_original_case(original_case)
        @linked_cases = [original_case]
        true
      else
        false
      end

    else
      process_linked_case_errors_for_ico(case_link, 'original_case_number')
      false
    end
  end

  def process_new_linked_cases_for_ico_related_params
    related_case_number = params[:related_case_number].strip
    case_link = LinkedCase.new(
      linked_case_number: related_case_number,
      type: :related
    )
    if case_link.valid?
      related_case = case_link.linked_case

      @linked_cases = process_ico_related_case_ids_param

      if validate_ico_related_case(related_case)
        @linked_cases << related_case
        true
      else
        false
      end
    else
      process_linked_case_errors_for_ico(case_link, 'related_case_number')
      false
    end
  end

  def process_linked_case_errors_for_ico(case_link, attribute)
    if case_link.errors[:linked_case_number].any?
      error = case_link.errors.details[:linked_case_number].first[:error]
      @linked_case_error = ico_error(attribute, error)
    elsif case_link.errors[:linked_case].any?
      @linked_case_error = case_link.errors[:linked_case].first
    else
      @linked_case_error = "invalid"
    end
  end

  def validate_ico_original_case(original_case)
    linkable = CaseLinkTypeValidator.classes_can_be_linked_with_type?(
      klass: 'Case::ICO::Base',
      linked_klass: original_case.class.to_s,
      type: 'original'
    )
    if not linkable
      @linked_case_error = ico_original_case_error('Case::ICO::Base')
      false
    elsif not policy(original_case).show?
      @linked_case_error = ico_error('original_case_number', :not_authorised)
      false
    else
      true
    end
  end

  def validate_ico_related_case(related_case)
    if related_case.number.in?(@linked_cases.map(&:number))
      @linked_case_error = ico_error('related_case_number', :already_linked)
      return false
    end

    original_case = Case::Base.find_by(
      number: params.fetch(:original_case_number)
    )

    if related_case == original_case
      @linked_case_error = ico_error('related_case_number', :already_linked)
      return false
    end

    unless policy(related_case).show?
      @linked_case_error = ico_error('related_case_number', :not_authorised)
      return false
    end

    if related_case.correspondence_type != original_case.correspondence_type
      @linked_case_error = ico_error('related_case_number',
                                     :does_not_match_original,
                                     related: related_case.type_abbreviation,
                                     original: original_case.type_abbreviation)
      return false
    end

    true
  end

  def process_ico_related_case_ids_param
    if params.fetch(:related_case_ids).present?
      Case::Base.where(id: params[:related_case_ids].split()).to_a
    else
      []
    end
  end

  def ico_error(attribute, error, options = {})
    klass = case options[:original]
            when 'FOI' then Case::ICO::FOI
            when 'SAR' then Case::ICO::SAR
            else Case::ICO::Base
            end
    helpers.translate_for_case(
      klass,
      'activerecord.errors.models',
      "#{attribute}.#{error}",
      options
    )
  end

  def ico_original_case_error(ico_class_name)
    allowed_case_class_names = []
    CaseLinkTypeValidator::ALLOWED_LINKS_BY_TYPE["original"][ico_class_name].each do | class_name |
      allowed_case_class_names << I18n.t("helpers.label.types.#{class_name}")
    end
    I18n.t('activerecord.errors.models.case/ico.original_case_number.wrong_type', 
      case_types: allowed_case_class_names.join(", "))
  end

  def respond_ico_params
    params.require(:ico).permit(
      :date_responded_dd,
      :date_responded_mm,
      :date_responded_yyyy,
    )
  end

  def ico_close_date_responded_params
    params.require(:ico).permit(
      :date_ico_decision_received_dd,
      :date_ico_decision_received_mm,
      :date_ico_decision_received_yyyy
    )
  end
end
