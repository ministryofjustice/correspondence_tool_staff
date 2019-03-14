class CaseCreateService

  include FOICasesParams
  include ICOCasesParams
  include SARCasesParams
  include OverturnedICOParams

  attr_reader :case, :result, :params, :flash_notice, :case_class

  def initialize(user, correspondence_type_key, params)
    @user                     = user
    @result                   = nil
    @correspondence_type_key  = correspondence_type_key
    @params                   = params
    @permitted_params         = create_params(correspondence_type_key)
    @correspondence_type      = CorrespondenceType.find_by_abbreviation(@correspondence_type_key.upcase)
    @case                     = create_case_of_default_subclass
    @flash_notice             = nil
    @case_class               = determine_case_class
  end

  def call
    create_case
  end

  private

  def create_case_of_default_subclass
    default_subclass = @correspondence_type.sub_classes.first
    @case = default_subclass.new
  end

  def create_params(correspondence_type)
    # Call case-specific create params, which we should be defined in concerns files.
    case correspondence_type
      when 'foi' then create_foi_params
      when 'sar' then create_sar_params
      when 'ico' then create_ico_params
      when 'overturned_foi' then create_ico_overturned_foi_params
      when 'overturned_sar' then create_ico_overturned_sar_params
    end
  end

  def create_case
    @case = @case_class.new(@permitted_params.merge(uploading_user: @user))

    if @case.invalid? || @result == :error
      @result = :error
    elsif flagged_for_disclosure_specialists_mismatch?
      set_flagged_for_disclosure_errors
      @result = :error
    else
      flag_for_disclosure_if_required
      overturned_ico_post_creation_processing if @case.overturned_ico?
      @result = :assign_responder
    end
    @result != :error
  end

  def overturned_ico_post_creation_processing
    @case.link_related_cases
  end

  def flagged_for_disclosure_specialists_mismatch?
    @case.requires_flag_for_disclosure_specialists? && @permitted_params[:flag_for_disclosure_specialists].blank?
  end

  def set_flagged_for_disclosure_errors
    @case.valid?
    @case.errors.add(:flag_for_disclosure_specialists, :blank)
  end

  def flag_for_disclosure_if_required
    @case.save!
    @flash_notice = "#{@case.decorate.pretty_type} case created<br/>Case number: #{@case.number}".html_safe

    if @permitted_params[:flag_for_disclosure_specialists] == 'yes'
      CaseFlagForClearanceService.new(
          user: @user,
          kase: @case,
          team: BusinessUnit.dacu_disclosure
      ).call
    end
    flag_for_disclosure if @case.is_a?(Case::ICO::Base)
  end

  def flag_for_disclosure
    service = CaseFlagForClearanceService.new(user: @user,
                                              kase: @case,
                                              team: BusinessUnit.dacu_disclosure)
    result = service.call
    raise "Unable to Flag ICO case for disclosure: #{result}" unless result == :ok
  end

  def determine_case_class
    case_class_service = GetCaseClassFromParamsService.new(
        type: @correspondence_type,
        params: @params["case_#{@correspondence_type_key}"]
      )
    case_class_service.call

    @result = :error if case_class_service.error?

    case_class_service.case_class
  end
end
