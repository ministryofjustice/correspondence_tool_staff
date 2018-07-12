class Case::OverturnedICO::SARDecorator < Case::BaseDecorator

  def subject
    "#{object.subject} - ICO appeal (SAR) #{object.original_ico_appeal.number}"
  end

end
