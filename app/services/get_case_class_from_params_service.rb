class GetCaseClassFromParamsService
  attr_accessor :case_class

  def initialize(type:, params:)
    @type_key = type.abbreviation.downcase
    @params = params
    @error_field = nil
    @error_message = nil
  end

  def call
    @case_class = case @type_key
                  when 'foi' then get_foi_case_class_from_params
                  when 'ico' then get_ico_case_class_from_params
                  when 'sar' then get_sar_case_class_from_params
                  when 'overturned_sar' then Case::OverturnedICO::SAR
                  when 'overturned_foi' then Case::OverturnedICO::FOI


                  else
                    raise RuntimeError.new(
                            "Unknown case type #{@type_key}"
                          )
                  end
  end

  def error?
    @error_field.present?
  end

  def set_error_on_case(kase)
    if error?
      kase.errors.add(@error_field, @error_message)
    else
      raise RuntimeError.new("No error present")
    end
  end

  private

  def get_foi_case_class_from_params
    if @params[:type].blank?
      @error_field = :type
      @error_message = :blank
      Case::FOI::Standard
    elsif @params[:type].in? %w{ Standard TimelinessReview ComplianceReview }
      "Case::FOI::#{@params.fetch(:type)}".constantize
    else
      @error_field = :type
      @error_message = :invalid
      Case::FOI::Standard
    end
  end

  def get_ico_case_class_from_params
    if !@params.key?(:original_case_id)
      @error_field = :original_case_id
      @error_message = :blank
      Case::ICO::FOI
    else
      original_case_id = @params.fetch(:original_case_id)
      original_case = Case::Base.find(original_case_id)
      case original_case.type_abbreviation
        when 'FOI' then Case::ICO::FOI
        when 'SAR' then Case::ICO::SAR
        else
          @error_field = :original_case_number
          @error_message = :invalid
          Case::ICO::FOI
      end
    end
  end

  def get_sar_case_class_from_params
    Case::SAR
  end

  def set_error_on_ico_case(kase)
    kase.errors.add(@error_field, @error_message)
    kase.original_case_type = params[:original_case_type]
  end

end
