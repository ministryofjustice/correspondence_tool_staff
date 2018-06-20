class Case::ICO::FOI < Case::ICO::Base

  def self.decorator_class
    Case::ICO::FOIDecorator
  end

  def type_abbreviation
    'ICO_FOI'
  end

  def param_type
    :case_ico_foi
  end
end
