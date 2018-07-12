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
    unless @result == :error
      create_case
    end
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
      when 'overturned_sar' then create_overturned_ico_params
    end
  end

  def create_case
    @case = @case_class.new(@permitted_params.merge(uploading_user: @user))

    if @case.invalid?
      @result = :error
    elsif @case.requires_flag_for_disclosure_specialists? && @permitted_params[:flag_for_disclosure_specialists].blank?
      @case.valid?
      @case.errors.add(:flag_for_disclosure_specialists, :blank)
      @result = :error
    else
      @case.save!
      @flash_notice = "#{@case.type_abbreviation} case created<br/>Case number: #{@case.number}".html_safe

      if @permitted_params[:flag_for_disclosure_specialists] == 'yes'
        CaseFlagForClearanceService.new(
          user: @user,
          kase: @case,
          team: BusinessUnit.dacu_disclosure
        ).call
      end
      flag_for_disclosure if @case.is_a?(Case::ICO::Base)
      @result = :assign_responder
    end
    @result != :error
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
    case_class_service.call()

    if case_class_service.error?
      @result = :error
      case_class_service.set_error_on_case(@case)
      Case::FOI::Standard
    else
      case_class_service.case_class
    end
  end
end
