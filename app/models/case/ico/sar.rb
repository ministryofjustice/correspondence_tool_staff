class Case::ICO::SAR < Case::ICO::Base

  has_paper_trail only: [
      :properties,
      :received_date,
      :escalation_date,
      :subject,
  ]

  def self.decorator_class
    Case::ICO::SARDecorator
  end

  def original_case_type; 'SAR' end


end
