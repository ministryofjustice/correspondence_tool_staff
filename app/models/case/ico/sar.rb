class Case::ICO::SAR < Case::ICO::Base

  def self.decorator_class
    Case::ICO::SARDecorator
  end

  def original_case_type; 'SAR' end
end
