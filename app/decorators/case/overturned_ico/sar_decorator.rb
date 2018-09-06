class Case::OverturnedICO::SARDecorator < Case::OverturnedICO::BaseDecorator

  def original_case_description
    "ICO appeal (SAR) #{object.original_ico_appeal.number}"
  end
end
