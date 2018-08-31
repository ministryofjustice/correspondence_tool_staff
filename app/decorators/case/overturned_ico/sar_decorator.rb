class Case::OverturnedICO::SARDecorator < Case::BaseDecorator

  def internal_deadline
    I18n.l(object.internal_deadline, format: :default)
  end

  def original_case_description
    "ICO appeal (SAR) #{object.original_ico_appeal.number}"
  end
end
