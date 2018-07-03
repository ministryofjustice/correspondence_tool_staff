class GetCaseClassFromParamsService
  attr_accessor :case_class

  def initialize(type:, params:)
    @type = type
    @type_key = @type.abbreviation.downcase
    @params = params
    @error_field = nil
    @error_message = nil
  end

  def call()
    if validate_params()
      @case_class = case @type_key
                   when 'foi' then get_foi_case_class_from_params
                   when 'ico' then get_ico_case_class_from_params
                   when 'sar' then get_sar_case_class_from_params
                   else
                     raise RuntimeError.new(
                             "Unknown case type #{@type_key}"
                           )
                   end
    end
  end

  def error?
    @error_field.present?
  end

  def set_error_on_case(kase)
    if error?
      kase.errors.add(@error_field, @error_message)
      # case @type_key
      # when 'foi' then set_error_on_foi_case(kase)
      # when 'ico' then set_error_on_ico_case(kase)
      # when 'sar' then set_error_on_sar_case(kase)
      # end
    else
      raise RuntimeError.new("No error present")
    end
  end

  private

  def get_foi_case_class_from_params()
    "Case::FOI::#{@params.fetch(:type)}".safe_constantize
  end

  def get_ico_case_class_from_params()
    case @params.fetch(:original_case_type).downcase
    when 'foi' then Case::ICO::FOI
    when 'sar' then Case::ICO::SAR
    end
  end

  def get_sar_case_class_from_params()
    Case::SAR
  end

  def set_error_on_ico_case(kase)
    kase.errors.add(@error_field, @error_message)
    kase.original_case_type = params[:original_case_type]
  end

  def validate_params()
    case @type_key
    when 'foi' then validate_foi_case_class_params
    when 'ico' then validate_ico_case_class_params
    when 'sar' then validate_sar_case_class_params
    else
      raise RuntimeError.new("Unknown case type #{@type_key}")
    end
  end

  def validate_foi_case_class_params()
    if @params[:type].blank?
      @error_field = :original_case_type
      @error_message = :blank
      false
    elsif !@params[:type].in?(['Standard', 'Timeliness', 'Compliance'])
      @error_field = :type
      @error_message = :invalid
      false
    else
      true
    end
  end

  def validate_ico_case_class_params()
    if !@params.key?(:original_case_type)
      @error_field = :original_case_type
      @error_message = :blank
      false
    elsif !@params[:original_case_type].in?(['FOI', 'SAR'])
      @error_field = :original_case_type
      @error_message = :invalid
      false
    else
      true
    end
  end

  def validate_sar_case_class_params()
    true
  end
end

