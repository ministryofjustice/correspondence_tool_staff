class Case::OverturnedICO::SARDecorator < Case::OverturnedICO::BaseDecorator

  def original_case_description
    "ICO appeal (SAR) #{object.original_ico_appeal.number}"
  end

  def missing_info
    if object.closed?
      object.refusal_reason&.abbreviation == 'tmm' ? 'yes' : 'no'
    end
  end
end
