class Case::ICO::FOI < Case::ICO::Base

  def self.decorator_class
    Case::ICO::FOIDecorator
  end

  def original_case_type; 'FOI' end

  def has_overturn?
    linked_cases.pluck(:type).include?('Case::OverturnedICO::FOI')
  end

end
