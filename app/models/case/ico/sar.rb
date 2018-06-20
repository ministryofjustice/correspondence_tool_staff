class Case::ICO::SAR < Case::ICO::Base

  def self.decorator_class
    Case::ICO::SARDecorator
  end

  def type_abbreviation
    'ICO_SAR'
  end

  def param_type
    :case_ico_sar
  end
end
