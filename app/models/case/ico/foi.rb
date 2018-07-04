class Case::ICO::FOI < Case::ICO::Base

  def self.decorator_class
    Case::ICO::FOIDecorator
  end

  def original_case_type; 'FOI' end
end
